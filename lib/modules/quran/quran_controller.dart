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
/// The reward is decided entirely by the server: opening a page starts a clock
/// there, and turning the page asks whether it was served. This controller
/// keeps a local timer only so the UI can show progress; it never decides that
/// points are due.
class QuranController extends GetxController {
  final _api = Get.find<ApiProvider>();
  final _storage = Get.find<StorageProvider>();

  final loading = true.obs;
  final failed = false.obs;

  final page = 1.obs;
  final totalPages = 604.obs;
  final requiredSeconds = 60.obs;
  final pagePoints = 20.obs;

  /// Seconds spent on the current page, for the subtle reading indicator.
  final elapsed = 0.obs;

  /// Pages already banked — shown in the index and used to hide the timer.
  final completed = <int>{}.obs;

  final pagesCompleted = 0.obs;
  final totalPoints = 0.obs;
  final totalSeconds = 0.obs;

  /// Set briefly when a page is rewarded, so the view can play its animation.
  final rewardFlash = 0.obs;

  /// How many pages may earn the reward per day, and how many already have
  /// today. The server enforces the limit; these only let the reader stop
  /// counting down toward a reward that can't come.
  final dailyRewardPages = 1.obs;
  final rewardedToday = 0.obs;

  bool get dailyRewardDone => rewardedToday.value >= dailyRewardPages.value;

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
    final r = requiredSeconds.value;
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
      pagePoints.value = _asInt(res['page_points'], 20);
      dailyRewardPages.value = _asInt(res['daily_rewarded_pages'], 1);
      pageEdition.value = res['page_edition']?.toString() ?? '';

      completed
        ..clear()
        ..addAll(
          (res['completed_pages'] as List? ?? []).map((e) => _asInt(e, 0)),
        );

      // Where they stopped: the server's record when it has one, otherwise the
      // copy this device keeps.
      var resume = _storage.quranLastPage;
      final progress = res['progress'];
      if (progress is Map) {
        pagesCompleted.value = _asInt(progress['pages_completed'], 0);
        totalPoints.value = _asInt(progress['total_points'], 0);
        totalSeconds.value = _asInt(progress['total_seconds'], 0);
        resume = _asInt(progress['last_page'], resume);
        rewardedToday.value = _asInt(progress['rewarded_today'], 0);
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

  /// Moves to [target]. Completing the page the reader is leaving is handled
  /// first, so the reward lands on the page actually read.
  Future<void> goTo(int target, {bool countPrevious = true}) async {
    final clamped = target.clamp(1, totalPages.value);
    if (clamped == page.value) return;

    final leaving = page.value;
    page.value = clamped;

    if (countPrevious) unawaited(_completePage(leaving));
    _openCurrentPage();
  }

  /// Opens the reader on [target] — from page 0, or a jump from the index.
  ///
  /// Arriving by a jump isn't "finishing" the page that was open, so it never
  /// banks a reward.
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
      goTo(p, countPrevious: false);
    } else if (!alreadyReading) {
      _openCurrentPage();
    }
  }

  /// The reader has closed. The page being left is not completed — the reward
  /// belongs to reading forward — and its clock stops, so no time counts while
  /// nothing is on screen. A highlighted passage and a tapped ayah belong to
  /// that reading, so they go too.
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

    // An already-banked page has nothing left to earn, so no clock is started.
    if (isCurrentPageCompleted) return;

    // Still opened on the server once today's reward is taken: the server
    // decides, and a session that runs past midnight can earn again. Only the
    // countdown is skipped.
    unawaited(_notifyOpen(page.value));
    if (dailyRewardDone) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;
      elapsed.value = elapsed.value + 1;
      if (elapsed.value >= requiredSeconds.value) _ticker?.cancel();
    });
  }

  Future<void> _notifyOpen(int p) async {
    try {
      await _api.quranPageOpen(p);
    } catch (e) {
      // A failed open just means this page can't be rewarded yet; reading
      // continues normally.
      ErrorReporter.report(e, StackTrace.current);
    }
  }

  /// Asks the server whether the page just left earned its points.
  Future<void> _completePage(int p) async {
    if (completed.contains(p)) return;

    try {
      final res = await _api.quranPageComplete(p);

      // Every answer carries today's count — a refusal for the daily limit
      // included — so the reader learns the day is done either way.
      dailyRewardPages.value = _asInt(
        res['daily_rewarded_pages'],
        dailyRewardPages.value,
      );
      final today = res['progress'];
      if (today is Map) {
        rewardedToday.value = _asInt(
          today['rewarded_today'],
          rewardedToday.value,
        );
      }
      if (dailyRewardDone) {
        // The page now open was started before this answer arrived; its
        // countdown would promise a reward the server will refuse.
        _ticker?.cancel();
        elapsed.value = 0;
      }

      if (res['status']?.toString() != 'rewarded') return;

      completed.add(p);
      pagesCompleted.value = pagesCompleted.value + 1;
      rewardFlash.value = _asInt(res['points_awarded'], pagePoints.value);

      final progress = res['progress'];
      if (progress is Map) {
        totalPoints.value = _asInt(progress['total_points'], totalPoints.value);
        totalSeconds.value = _asInt(
          progress['total_seconds'],
          totalSeconds.value,
        );
      }

      _syncCachedUser(res);
      unawaited(_maybeShowLevelUp(res));
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    }
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
