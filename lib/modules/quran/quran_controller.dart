import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/constants/quran_surahs.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../level_up/level_up_popup.dart';
import 'quran_ayah_geometry.dart';
import 'quran_page_cache.dart';

/// Quran Werd — reading state, page caching and the page-completion reward.
///
/// Every page held for the required time and then turned is reported to the
/// server, which records it for the reader's statistics and decides whether it
/// also earns the day's points. The local timer only measures the reading; it
/// never decides that points are due.
class QuranController extends GetxController {
  final _api = Get.find<ApiProvider>();
  final _storage = Get.find<StorageProvider>();

  final loading = true.obs;
  final failed = false.obs;

  final page = 1.obs;
  final totalPages = 604.obs;
  final requiredSeconds = 60.obs;
  final pagePoints = 20.obs;

  /// Short pages with their own, shorter reading time — Al-Fatiha and the
  /// opening of Al-Baqarah — as the server sets them. Other pages use
  /// [requiredSeconds].
  final requiredSecondsByPage = <int, int>{}.obs;

  int requiredSecondsFor(int p) =>
      requiredSecondsByPage[p] ?? requiredSeconds.value;

  /// Seconds spent on the current page, for the subtle reading indicator.
  final elapsed = 0.obs;

  /// Pages already banked — shown in the index and used to hide the timer.
  final completed = <int>{}.obs;

  final pagesCompleted = 0.obs;
  final totalPoints = 0.obs;
  final totalSeconds = 0.obs;

  /// Different pages read toward the current khatma, and khatmas finished. The
  /// count starts over from 0 each time every page has been read.
  final khatmaPages = 0.obs;
  final khatmasCompleted = 0.obs;

  /// Set briefly when a page is rewarded, so the view can play its animation.
  final rewardFlash = 0.obs;

  /// How many pages may earn the reward per day, and how many already have
  /// today. The server enforces the limit; these only let the reader stop
  /// counting down toward a reward that can't come.
  final dailyRewardPages = 1.obs;
  final rewardedToday = 0.obs;

  /// The day [rewardedToday] was counted on. Once the date changes the reward
  /// is open again, even before the server has said so.
  DateTime _countsDay = _today();

  bool get dailyRewardDone =>
      _countsDay == _today() && rewardedToday.value >= dailyRewardPages.value;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The pagination the page images follow, as the server reports it. Page
  /// numbers in the mood and feeling lists are verified for the 604-page
  /// Madinah Mushaf, so they're offered for opening only when this matches.
  final pageEdition = ''.obs;

  static const verifiedPageEdition = 'madinah_hafs_604';

  bool get pagesMatchReader => pageEdition.value == verifiedPageEdition;

  /// Night reading mode — persisted, so it survives leaving the Mushaf.
  late final nightMode = _storage.quranNightMode.obs;

  /// "Page 0": the cover the Mushaf opens on, offering the index, a random
  /// page, the bookmark and the last page read. Nothing is opened — and no
  /// reading clock started — until the reader picks one.
  final coverVisible = true.obs;

  /// The page last opened for reading, on this device or (via the server) any.
  final lastReadPage = 1.obs;

  /// The one saved bookmark, kept on the device. Null when none is set.
  late final bookmarkPage = RxnInt(_storage.quranBookmark);

  /// Ayahs set apart on the page — the passage a feeling result pointed to.
  final highlight = Rxn<AyahRange>();

  /// The ayah the reader tapped, while its details are showing.
  final selectedAyah = Rxn<AyahRef>();

  String _template = '';
  Timer? _ticker;
  bool _levelUpShowing = false;

  SurahInfo get currentSurah => surahForPage(page.value);

  void toggleNightMode() {
    nightMode.value = !nightMode.value;
    _storage.quranNightMode = nightMode.value;
  }

  bool get isCurrentPageCompleted => completed.contains(page.value);

  bool get isCurrentPageBookmarked => bookmarkPage.value == page.value;

  /// Bookmarks the page being read, or clears the bookmark if it is already
  /// on this page. One bookmark only: setting it elsewhere moves it.
  void toggleBookmark() {
    final next = isCurrentPageBookmarked ? null : page.value;
    bookmarkPage.value = next;
    _storage.quranBookmark = next;
  }

  /// 0..1 toward the required reading time.
  double get readingProgress {
    final r = requiredSecondsFor(page.value);
    if (r <= 0) return 1;
    return (elapsed.value / r).clamp(0.0, 1.0);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    failed.value = false;
    try {
      final res = await _api.quranWerd();

      _template = res['page_image_template']?.toString() ?? '';
      totalPages.value = _asInt(res['total_pages'], 604);
      requiredSeconds.value = _asInt(res['required_seconds'], 60);
      final byPage = res['required_seconds_by_page'];
      requiredSecondsByPage.assignAll({
        if (byPage is Map)
          for (final entry in byPage.entries)
            ?int.tryParse('${entry.key}'): _asInt(
              entry.value,
              requiredSeconds.value,
            ),
      });
      pagePoints.value = _asInt(res['page_points'], 20);
      dailyRewardPages.value = _asInt(res['daily_rewarded_pages'], 1);
      pageEdition.value = res['page_edition']?.toString() ?? '';

      completed
        ..clear()
        ..addAll(
          (res['completed_pages'] as List? ?? []).map((e) => _asInt(e, 0)),
        );

      // Where they stopped: this device's own record first — it also knows
      // pages opened but not finished — then the server's.
      final local = _storage.quranLastPageOrNull;
      var resume = local ?? 1;
      final progress = res['progress'];
      if (progress is Map) {
        _applyProgress(progress);
        if (local == null) resume = _asInt(progress['last_page'], resume);
      }
      page.value = resume.clamp(1, totalPages.value);
      lastReadPage.value = page.value;

      debugPrint(
        '[quran] template=$_template  pages=${totalPages.value}  '
        'resume=${page.value}  completed=${completed.length}',
      );

      loading.value = false;

      // A one-off inventory of what this device already holds, so an offline
      // report can be read straight off the log.
      unawaited(QuranPageCache.logHeld(totalPages.value, imageUrlFor));
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      failed.value = true;
      loading.value = false;
    }
  }

  /// The image URL for [p]. Empty when no provider is configured.
  String imageUrlFor(int p) {
    if (_template.isEmpty) return '';
    return _template
        .replaceAll('{page3}', p.toString().padLeft(3, '0'))
        .replaceAll('{page}', p.toString());
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  /// Moves to [target]. The page being left needs nothing more: a page counts
  /// as read the moment its reading time is up, whether or not it is turned.
  void goTo(int target) {
    final clamped = target.clamp(1, totalPages.value);
    if (clamped == page.value) return;

    page.value = clamped;
    _openCurrentPage();
  }

  /// Opens the reader on [target] — from page 0, or a jump from the index.
  void openAt(int target) {
    final wasReading = !coverVisible.value;
    coverVisible.value = false;
    _startReadingAt(target, alreadyReading: wasReading);
  }

  /// Opens [target] in a reader stacked over another screen — a passage picked
  /// from the "read by how you feel" results — without leaving page 0
  /// underneath, so back returns to that screen rather than the cover.
  ///
  /// [highlight] is set apart on every page it spans until the reader closes.
  void readAt(int target, {AyahRange? highlight}) {
    this.highlight.value = highlight;
    selectedAyah.value = null;
    _startReadingAt(target, alreadyReading: false);
  }

  /// Arriving on the page that is already current still has to open it when
  /// nothing was being read: `goTo` would see no change and do nothing, and the
  /// reading clock would never start.
  void _startReadingAt(int target, {required bool alreadyReading}) {
    final p = target.clamp(1, totalPages.value);
    if (p != page.value) {
      goTo(p);
    } else if (!alreadyReading) {
      _openCurrentPage();
    }
  }

  /// The reader has closed. The page's clock stops, so no time counts while
  /// nothing is on screen — a page whose reading time wasn't up isn't counted.
  /// A highlighted passage and a tapped ayah belong to that reading, so they
  /// go too.
  void stopReading() {
    _ticker?.cancel();
    elapsed.value = 0;
    highlight.value = null;
    selectedAyah.value = null;
  }

  /// Back to page 0.
  void showCover() {
    stopReading();
    coverVisible.value = true;
  }

  bool get canGoNext => page.value < totalPages.value;
  bool get canGoPrevious => page.value > 1;

  void randomPage() {
    final target = Random().nextInt(totalPages.value) + 1;
    if (coverVisible.value) {
      openAt(target);
    } else {
      goTo(target);
    }
  }

  // ── Reading clock ──────────────────────────────────────────────────────

  void _openCurrentPage() {
    _ticker?.cancel();
    elapsed.value = 0;

    _precacheAround(page.value);
    _storage.quranLastPage = page.value;
    lastReadPage.value = page.value;

    // Opening a page sends nothing. Once the page has been on screen for its
    // reading time it is reported straight away — no turn needed — whether or
    // not it can still earn points. The clock then stops, so it is reported
    // once per visit.
    final p = page.value;
    final required = requiredSecondsFor(p);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;
      elapsed.value = elapsed.value + 1;
      if (elapsed.value >= required) {
        _ticker?.cancel();
        unawaited(_completePage(p, elapsed.value));
      }
    });
  }

  /// Reports [p], read for [seconds] — its full reading time. The server
  /// records every such page and adds points only when today's reward is still
  /// open.
  Future<void> _completePage(int p, int seconds) async {
    try {
      final res = await _api.quranPageComplete(p, seconds);

      dailyRewardPages.value = _asInt(
        res['daily_rewarded_pages'],
        dailyRewardPages.value,
      );
      // Every answer carries the totals and today's count, whether or not
      // this page earned anything.
      final progress = res['progress'];
      if (progress is Map) _applyProgress(progress);

      if (res['status']?.toString() != 'rewarded') return;

      completed.add(p);
      rewardFlash.value = _asInt(res['points_awarded'], pagePoints.value);

      _syncCachedUser(res);
      unawaited(_maybeShowLevelUp(res));
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    }
  }

  /// The reader's totals and today's reward count, as the server reports them.
  void _applyProgress(Map<dynamic, dynamic> progress) {
    pagesCompleted.value = _asInt(
      progress['pages_completed'],
      pagesCompleted.value,
    );
    totalPoints.value = _asInt(progress['total_points'], totalPoints.value);
    totalSeconds.value = _asInt(progress['total_seconds'], totalSeconds.value);
    khatmaPages.value = _asInt(progress['khatma_pages'], khatmaPages.value);
    khatmasCompleted.value = _asInt(
      progress['khatmas_completed'],
      khatmasCompleted.value,
    );
    rewardedToday.value = _asInt(
      progress['rewarded_today'],
      rewardedToday.value,
    );
    _countsDay = _today();
  }

  // ── Image caching ──────────────────────────────────────────────────────

  /// Warms the store for the page either side, so a turn is instant. A page
  /// this device already holds is skipped entirely, so nothing is ever
  /// downloaded twice.
  void _precacheAround(int p) {
    for (final n in [p + 1, p - 1]) {
      if (n < 1 || n > totalPages.value) continue;
      final url = imageUrlFor(n);
      if (url.isEmpty || !url.startsWith('http')) continue;

      // Nothing is re-fetched: a page the device already holds is skipped
      // outright, and concurrent requests for the same page share one download.
      unawaited(
        QuranPageCache.has(url)
            .then((held) {
              if (held) return null;
              debugPrint('[quran] page $p — fetching neighbour $n');
              return QuranPageCache.fetch(url);
            })
            .catchError((Object _) => null),
      );
    }
  }

  // ── Points / level plumbing, matching the prayer flow ──────────────────

  void _syncCachedUser(Map<String, dynamic> res) {
    final cached = _storage.cachedUser;
    if (cached == null) return;

    final updated = Map<String, dynamic>.from(cached);
    if (res['total_points'] != null) {
      updated['total_points'] = res['total_points'];
    }
    if (res['score'] != null) updated['score'] = res['score'];
    if (res['level'] is Map) updated['level'] = res['level'];
    _storage.cachedUser = updated;
  }

  Future<void> _maybeShowLevelUp(Map<String, dynamic> res) async {
    if (res['level_changed'] != true || _levelUpShowing) return;
    final newLevelJson = res['new_level'];
    if (newLevelJson is! Map) return;

    final cached = _storage.cachedUser;
    _levelUpShowing = true;
    try {
      await LevelUpPopup.show(
        name: (cached?['name'] as String?) ?? '',
        avatarUrl: cached?['avatar_url'] as String?,
        newLevel: LevelInfo.fromJson(Map<String, dynamic>.from(newLevelJson)),
        totalPoints: _asInt(res['total_points'], 0),
      );
    } finally {
      _levelUpShowing = false;
    }
  }

  static int _asInt(dynamic v, int fallback) =>
      (v as num?)?.round() ?? fallback;
}
