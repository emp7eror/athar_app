import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/constants/quran_surahs.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../level_up/level_up_popup.dart';
import 'khatma_popup.dart';
import 'quran_ayah_geometry.dart';
import 'quran_page_cache.dart';

/// Quran Werd — reading state, page caching and the page-completion reward.
///
/// Every page held for the required time and then turned is reported to the
/// server, which records it for the reader's statistics and decides whether it
/// also earns the day's points. The local timer only measures the reading; it
/// never decides that points are due.
class QuranController extends GetxController with WidgetsBindingObserver {
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

  /// Pages that have earned their reward — they can't earn again.
  final completed = <int>{}.obs;

  /// Every page ever counted as read, rewarded or not.
  final readPages = <int>{}.obs;

  /// Pages read in the current khatma — what is left before it is complete.
  /// Starts empty again once a khatma is finished.
  final khatmaReadPages = <int>{}.obs;

  /// First and last page of each surah (index 0 = Al-Fatiha), as the server
  /// works them out from the Mushaf metadata. Estimated from the surah start
  /// pages when the server doesn't send them.
  List<(int, int)> _surahPages = const [];

  final pagesCompleted = 0.obs;
  final totalPoints = 0.obs;
  final totalSeconds = 0.obs;

  /// Words and letters of every page read (re-reads included), and whether
  /// the server has the per-page counts to work them out.
  final wordsRead = 0.obs;
  final lettersRead = 0.obs;
  final wordCountsAvailable = false.obs;

  /// The most extra time one visit to a page may add, as the server caps it.
  int _maxCreditedSeconds = 1800;

  // ── The current page visit ──
  /// The page being timed, or null when nothing is being read.
  int? _visitPage;

  /// Whether this visit has already been counted as a read.
  bool _visitCounted = false;

  /// Of [elapsed], how much has already been sent to the server.
  int _reportedSeconds = 0;

  /// The clock was stopped because the app left the foreground.
  bool _pausedByApp = false;

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

  /// Read on an earlier visit (or already in this one).
  bool get isCurrentPageRead => readPages.contains(page.value);

  // ── Khatma progress ────────────────────────────────────────────────────

  /// Read in the current khatma.
  bool isReadInKhatma(int p) => khatmaReadPages.contains(p);

  /// First and last page of [surah]. A page shared with the surah before or
  /// after counts for both.
  (int, int) surahPages(int surah) {
    if (surah >= 1 && surah <= _surahPages.length) return _surahPages[surah - 1];
    if (surah < 1 || surah > kQuranSurahs.length) return (1, 1);
    final first = kQuranSurahs[surah - 1].page;
    final last = surah < kQuranSurahs.length
        ? max(first, kQuranSurahs[surah].page)
        : totalPages.value;
    return (first, last);
  }

  /// First and last page of [juz] (1–30).
  (int, int) juzPages(int juz) {
    final first = kJuzStartPages[juz - 1];
    final last = juz < kJuzStartPages.length
        ? max(first, kJuzStartPages[juz] - 1)
        : totalPages.value;
    return (first, last);
  }

  /// Pages of [first]..[last] read in the current khatma.
  ({int read, int total}) khatmaProgress(int first, int last) {
    var read = 0;
    for (var p = first; p <= last; p++) {
      if (khatmaReadPages.contains(p)) read++;
    }
    return (read: read, total: last - first + 1);
  }

  /// The first page of [first]..[last] not yet read in this khatma.
  int? firstUnread(int first, int last) {
    for (var p = first; p <= last; p++) {
      if (!khatmaReadPages.contains(p)) return p;
    }
    return null;
  }

  /// The next page not yet read in this khatma after [after] — the last page
  /// read, by default — coming round to the start when needed. Null once
  /// every page is read.
  int? nextUnreadPage({int? after}) {
    final total = totalPages.value;
    final from = (after ?? lastReadPage.value).clamp(0, total);
    return firstUnread(from + 1, total) ?? firstUnread(1, from);
  }

  static List<(int, int)> _parseSurahPages(Object? data) {
    if (data is! List || data.length != kQuranSurahs.length) return const [];
    final pages = <(int, int)>[];
    for (final item in data) {
      if (item is! List || item.length != 2) return const [];
      final first = _asInt(item[0], 0);
      final last = _asInt(item[1], 0);
      if (first < 1 || last < first) return const [];
      pages.add((first, last));
    }
    return pages;
  }

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
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _flushExtraTime();
    super.onClose();
  }

  /// Time with the app in the background isn't reading: stop the clock and
  /// send what was read so far, then carry on from there when it returns.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final page = _visitPage;
    if (page == null) return;

    if (state == AppLifecycleState.resumed) {
      if (!_pausedByApp) return;
      _pausedByApp = false;
      _startTicker(page);
    } else if (!_pausedByApp) {
      _pausedByApp = true;
      _ticker?.cancel();
      _flushExtraTime();
    }
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
      _maxCreditedSeconds = _asInt(res['max_credited_seconds'], 1800);
      pageEdition.value = res['page_edition']?.toString() ?? '';

      completed
        ..clear()
        ..addAll(
          (res['completed_pages'] as List? ?? []).map((e) => _asInt(e, 0)),
        );
      readPages
        ..clear()
        ..addAll(
          (res['read_pages'] as List? ?? []).map((e) => _asInt(e, 0)),
        )
        // Older servers only send rewarded pages.
        ..addAll(completed);

      final khatmaList = res['khatma_read_pages'];
      final firstKhatma =
          res['progress'] is Map && _asInt((res['progress'] as Map)['khatmas_completed'], 0) == 0;
      khatmaReadPages
        ..clear()
        ..addAll(
          khatmaList is List
              ? khatmaList.map((e) => _asInt(e, 0))
              // Older servers: in the first khatma, every page read counts.
              : (firstKhatma ? readPages : const <int>{}),
        );
      _surahPages = _parseSurahPages(res['surah_pages']);

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

    // Leaving the page: whatever was read past its counted time goes now.
    _flushExtraTime();
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
    _flushExtraTime();
    _visitPage = null;
    _pausedByApp = false;
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
    _visitPage = page.value;
    _visitCounted = false;
    _reportedSeconds = 0;
    _pausedByApp = false;

    _precacheAround(page.value);
    _storage.quranLastPage = page.value;
    lastReadPage.value = page.value;

    _startTicker(page.value);
  }

  /// Opening a page sends nothing. Once the page has been on screen for its
  /// reading time it is reported straight away — no turn needed — whether or
  /// not it can still earn points. The clock keeps running after that: time
  /// spent on the page beyond it is sent when the reader leaves the page (or
  /// the app), up to the server's per-visit cap.
  void _startTicker(int p) {
    _ticker?.cancel();
    final required = requiredSecondsFor(p);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed || _visitPage != p) return;
      elapsed.value = elapsed.value + 1;

      if (!_visitCounted && elapsed.value >= required) {
        _visitCounted = true;
        _reportedSeconds = elapsed.value;
        unawaited(_completePage(p, elapsed.value));
      } else if (_visitCounted && elapsed.value - required >= _maxCreditedSeconds) {
        // Left open far longer than anyone reads a page — stop counting.
        _ticker?.cancel();
      }
    });
  }

  /// Sends the time read on the current page since it was last reported.
  /// Nothing for a page not yet counted as read this visit, and nothing for a
  /// few stray seconds.
  void _flushExtraTime() {
    final p = _visitPage;
    if (p == null || !_visitCounted) return;

    final extra = min(elapsed.value - _reportedSeconds, _maxCreditedSeconds);
    if (extra < 5) return;

    _reportedSeconds += extra;
    unawaited(_sendExtraTime(p, extra));
  }

  Future<void> _sendExtraTime(int p, int seconds) async {
    try {
      final res = await _api.quranPageTime(p, seconds);
      final progress = res['progress'];
      if (progress is Map && !isClosed) _applyProgress(progress);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    }
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

      // Recorded as read whether or not it earned anything.
      if (res['recorded'] == true) {
        readPages.add(p);
        khatmaReadPages.add(p);
      }
      // This page finished the khatma; the next one starts empty.
      if (res['khatma_completed'] == true) khatmaReadPages.clear();

      if (res['status']?.toString() == 'rewarded') {
        completed.add(p);
        final points = _asInt(res['points_awarded'], pagePoints.value);
        rewardFlash.value = points;
        _syncCachedUser(res);
        // Clear the flash once its animation has played. Left set, the view
        // replays "+points" on every later page (its key follows
        // pagesCompleted, which grows for unrewarded pages too) and whenever
        // the reader is reopened.
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!isClosed && rewardFlash.value == points) rewardFlash.value = 0;
        });
      } else {
        // Not rewarded (daily limit / already rewarded): nothing to show.
        rewardFlash.value = 0;
      }

      // A khatma can finish on any page, rewarded or not.
      unawaited(_celebrate(res));
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
    wordsRead.value = _asInt(progress['words_read'], wordsRead.value);
    lettersRead.value = _asInt(progress['letters_read'], lettersRead.value);
    wordCountsAvailable.value = progress['word_counts_available'] == true;
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

  /// One celebration at a time: a completed khatma first, then a level-up.
  Future<void> _celebrate(Map<String, dynamic> res) async {
    if (res['khatma_completed'] == true) {
      await KhatmaPopup.show(
        name: (_storage.cachedUser?['name'] as String?) ?? '',
        khatmas: khatmasCompleted.value,
        totalPages: totalPages.value,
      );
    }
    await _maybeShowLevelUp(res);
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
