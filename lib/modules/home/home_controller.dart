import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:athar/modules/home/missed_prayer_dialog.dart';
import 'package:athar/modules/home/prayer_confirm_dialog.dart';
import 'package:athar/modules/home/prayer_done_dialog.dart';
import 'package:get/get.dart';

import '../../core/services/adhan_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/timezone_service.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/prayer_log_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../level_up/level_up_popup.dart';

class HomeController extends GetxController {
  final _api = Get.find<ApiProvider>();
  final _adhan = Get.find<AdhanService>();
  final _location = Get.find<LocationService>();
  final _sound = Get.find<SoundService>();
  final _scheduler = Get.find<PrayerNotificationScheduler>();
  final StorageProvider _storage = Get.find<StorageProvider>();

  final checklist = <PrayerChecklistItem>[].obs;
  final pointsToday = 0.obs;
  /// Whether today's single "forgot to log it" allowance is already spent.
  final forgotToMarkUsed = false.obs;
  final totalPoints = 0.obs;
  final level = Rxn<LevelInfo>();
  final quote = ''.obs;
  final quoteSource = ''.obs;

  final nextPrayerKey = ''.obs;
  final countdown = '00:00:00'.obs;
  // Per-second "wall clock" so tiles can reactively re-evaluate time-sensitive
  // UI (on-time bonus countdown, window transitions) without each widget
  // spinning its own Timer.
  final now = DateTime.now().obs;

  // On-time bonus display hints — MUST mirror the server's PointsService
  // constants. Values displayed on the tile only; the actual award is decided
  // by the API response.
  static const onTimeBonusWindow = Duration(minutes: 30);
  static const onTimeBonusPoints = 10;

  /// Time remaining in the on-time bonus window for [prayerTime], or null if
  /// the prayer hasn't started, is already past its 30-min window, or has no
  /// known start time. Reactive on [now].
  Duration? onTimeBonusRemaining(DateTime? prayerTime) {
    if (prayerTime == null) return null;
    final elapsed = now.value.difference(prayerTime);
    if (elapsed.isNegative) return null; // not started
    final left = onTimeBonusWindow - elapsed;
    return left.isNegative ? null : left; // window closed
  }
  final loading = true.obs;
  final marking = ''.obs; // prayer currently being toggled
  final locationLabel = 'location_not_set'.obs;
  final updatingLocation = false.obs;
  final userName = ''.obs;
  final avatarUrl = ''.obs;

  Timer? _ticker;

  // Guards against a duplicate/stacked popup if two mark-prayer responses
  // both resolve with level_changed:true in quick succession.
  bool _levelUpShowing = false;

  /// Cached IANA identifier — the platform channel is only hit on a cold
  /// cache, not on every request. The server pins its own copy anyway.
  Future<String> get _tz => Get.find<TimezoneService>().resolve();

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    _refreshLocationLabel();
    _startCountdown();
    refreshAll();
    // Pin/refresh the server-side timezone. Safe here: this controller only
    // exists once the user is authenticated.
    unawaited(Get.find<TimezoneService>().syncIfChanged());
  }

  Future<void> refreshAll() async {
    loading.value = true;
    await Future.wait([_loadToday(), _loadQuote()]);
    loading.value = false;
  }

  Future<void> _loadToday() async {
    final now = DateTime.now();
    final isBeforeFajr = now.isBefore(_adhan.getTodayPrayerTimes().fajr);
    // قبل الفجر → اجلب أمس، غير ذلك → اليوم
    final referenceDate = isBeforeFajr ? now.subtract(const Duration(days: 1)) : now;
    final date = isBeforeFajr ? _formatDate(referenceDate) : null;
    final times = isBeforeFajr ? _adhan.getTodayPrayerTimes(date: referenceDate) : _adhan.getTodayPrayerTimes();
    final dayKey = _formatDate(referenceDate);

    // Show prayer times right away — before the network answers. Times are
    // computed on-device; completion/points come from the last cached server
    // response for this same prayer day, if there is one. The request below
    // then replaces this with the server's current state.
    if (_checklistDay != dayKey) _seedChecklist(dayKey, times);

    try {
      final tz = await _tz;
      final res = await _api.todayPrayers(tz, date: date);
      _applyToday(res, times);
      _checklistDay = dayKey;
      _storage.saveTodayPrayers(dayKey, res);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      // Prayer times themselves are computed on-device (AdhanService) and
      // never need the network — only completion/points state does. If the
      // request failed (most commonly: no internet), fall back to locally
      // computed times so the app stays usable offline instead of showing a
      // blank checklist. Server-known completion/points just can't be shown
      // until the next successful sync.
      if (checklist.isEmpty) {
        checklist.value = _adhan.orderedTimes(referenceDate)
            .map((p) => PrayerChecklistItem(
                  prayerName: p.key,
                  points: 0,
                  pointsEarned: 0,
                  isCompleted: false,
                ).copyWith(time: p.time))
            .toList();
      }

      if (e is ApiException) {
        AppSnackbar.error('app_name'.tr, e.message);
      } else {
        AppSnackbar.show('app_name'.tr, 'offline_mode_notice'.tr);
      }
    }
  }

  Future<void> _loadQuote() async {
    try {
      final q = await _api.randomQuote();
      quote.value = q['text'] ?? '';
      quoteSource.value = q['source'] ?? '';
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      /* non-critical */
    }
  }

  /// Local window check gates the checkbox before we ever hit the API.
  bool isActive(String prayerKey) {
    final p = Prayer.values.firstWhere((e) => e.name == prayerKey, orElse: () => Prayer.fajr);
    return _adhan.isPrayerTimeActive(p);
  }

  /// Entry point from the tile tap. Already-completed prayers are a no-op;
  /// active prayers use the normal on-time confirmation; a prayer whose start
  /// time has passed but whose window has closed uses the missed flow.
  /// Prayers that haven't reached their scheduled time yet are rejected — the
  /// user can neither mark nor mute them until they actually start.
  Future<void> mark(PrayerChecklistItem item) async {
    if (item.isCompleted) return;

    // Reject future prayers outright (defense-in-depth; the UI also locks them).
    if (item.time != null && item.time!.isAfter(DateTime.now())) {
      AppSnackbar.error('app_name'.tr, 'prayer_not_started_yet'.tr);
      return;
    }

    if (isActive(item.prayerName)) {
      await _markOnTime(item);
    } else {
      await _markMissed(item);
    }
  }

  Future<void> _markOnTime(PrayerChecklistItem item) async {
    final result = await PrayerConfirmDialog.show(item.prayerName, item.points);
    if (result == null) return; // المستخدم ألغى

    marking.value = item.prayerName;
    try {
      final timezone = await _tz;
      final res = await _api.markPrayer(
        item.prayerName,
        completed: true,
        tz: timezone,
        prayerDate: _prayerDate(item.prayerName),
        prayerTime: item.time?.toIso8601String(),
        difficulty: result.difficulty.name,
        mood: result.mood.name,
        note: result.note.isEmpty ? null : result.note,
      );

      totalPoints.value = res['total_points'] ?? totalPoints.value;
      if (res['level'] is Map) level.value = LevelInfo.fromJson(res['level']);
      try {
        await _sound.playPrayerDone(); // completion chime
      } catch (e) {
        ErrorReporter.report(e, StackTrace.current);

      }
      // Prayer's logged — the pre-scheduled "did you pray?" nudges for it
      // today (at-time + 30-min-after) would otherwise still fire.
      unawaited(_scheduler.cancelRemindersFor(item.prayerName, occurredOn: item.time));
      await _loadToday();
      // Motivational feedback shown only AFTER the API save + reload succeed.
      await PrayerDoneDialog.showOnTime();
      await _maybeShowLevelUp(res);
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      AppSnackbar.error('app_name'.tr, e.message);
    } finally {
      marking.value = '';
    }
  }

  /// Logs a prayer whose scheduled window has closed. The reason is required
  /// (dialog enforces it); the state is only updated after the API succeeds.
  Future<void> _markMissed(PrayerChecklistItem item) async {
    final result = await MissedPrayerDialog.show(
      item.prayerName,
      allowForgotToMark: !forgotToMarkUsed.value,
    );
    if (result == null) return;

    marking.value = item.prayerName;
    try {
      final timezone = await _tz;
      final res = await _api.markPrayer(
        item.prayerName,
        completed: true,
        tz: timezone,
        prayerDate: _prayerDate(item.prayerName),
        prayerTime: item.time?.toIso8601String(),
        // "Forgot to mark" means the prayer *was* on time — only the logging
        // was late — so it isn't flagged as performed outside its window.
        performedOutsideTime: !result.reason.prayedOnTime,
        reason: result.reason.apiValue,
        note: result.note.isEmpty ? null : result.note,
      );

      totalPoints.value = res['total_points'] ?? totalPoints.value;
      if (res['level'] is Map) level.value = LevelInfo.fromJson(res['level']);
      try {
        await _sound.playPrayerDone();
      } catch (e) {ErrorReporter.report(e, StackTrace.current);
      }
      unawaited(_scheduler.cancelRemindersFor(item.prayerName, occurredOn: item.time));
      await _loadToday(); // reactive checklist now shows it as done + outside-time
      await PrayerDoneDialog.showOutsideTime();
      await _maybeShowLevelUp(res);
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      // Failure path: intentionally do NOT touch checklist / points state.
      AppSnackbar.error('app_name'.tr, e.message);
    } finally {
      marking.value = '';
    }
  }

  Future<void> updateLocation() async {
    updatingLocation.value = true;
    try {
      await _location.refreshFromDevice();
      _refreshLocationLabel();
      await refreshAll(); // re-pull today with the new coords
      _startCountdown(); // restart the next-prayer ticker
      await _scheduler.reschedule(); // prayer times changed → rebuild alarms
      _storage.locationSetBefore = true;
      AppSnackbar.show('app_name'.tr, 'location_updated'.tr);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      AppSnackbar.error('app_name'.tr, (e is String ? e : 'location_error').tr);
    } finally {
      updatingLocation.value = false;
    }
  }

  void _startCountdown() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
      final next = _adhan.nextPrayer();
      nextPrayerKey.value = AdhanService.prayerKey(next.prayer);
      final diff = next.time.difference(now.value);
      final d = diff.isNegative ? Duration.zero : diff;
      String two(int n) => n.toString().padLeft(2, '0');
      countdown.value = '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  void _refreshLocationLabel() {
    final s = Get.find<StorageProvider>();
    final isAr = Get.locale?.languageCode == 'ar';
    final city = isAr ? s.cityAr : s.cityEn;
    if (city != null && city.isNotEmpty) {
      locationLabel.value = city; // "مكة المكرمة" or "Makkah"
    } else if (s.lat != null && s.lng != null) {
      locationLabel.value = '${s.lat!.toStringAsFixed(3)}, ${s.lng!.toStringAsFixed(3)}';
    }
  }

  /// Shows the full-screen celebration popup when [res] (the raw markPrayer
  /// response) reports a level promotion. Guarded against duplicate/stacked
  /// popups if multiple mark-prayer calls resolve close together.
  Future<void> _maybeShowLevelUp(Map<String, dynamic> res) async {
    if (res['level_changed'] != true || _levelUpShowing) return;
    final newLevelJson = res['new_level'];
    if (newLevelJson is! Map) return;

    _levelUpShowing = true;
    try {
      await LevelUpPopup.show(
        name: userName.value,
        avatarUrl: avatarUrl.value,
        newLevel: LevelInfo.fromJson(Map<String, dynamic>.from(newLevelJson)),
        totalPoints: totalPoints.value,
      );
    } finally {
      _levelUpShowing = false;
    }
  }

  void _loadUserInfo() {
    final u = Get.find<StorageProvider>().cachedUser;
    userName.value = (u?['name'] as String?) ?? '';
    avatarUrl.value = (u?['avatar_url'] as String?) ?? '';
    if (u?['level'] is Map) level.value = LevelInfo.fromJson(u!['level']);
    totalPoints.value = (u?['total_points'] as int?) ?? totalPoints.value;
  }

  /// The prayer day (`YYYY-MM-DD`) the current [checklist] belongs to.
  String? _checklistDay;

  /// Fills [checklist] instantly, without the network: the cached server
  /// response when it's for [dayKey], otherwise on-device times with nothing
  /// completed yet (base points borrowed from any earlier response).
  void _seedChecklist(String dayKey, PrayerTimes times) {
    final cache = _storage.todayPrayersCache;
    final res = cache?['res'];

    if (res is Map && cache!['date'] == dayKey) {
      try {
        _applyToday(Map<String, dynamic>.from(res), times);
        _checklistDay = dayKey;
        return;
      } catch (e) {
        ErrorReporter.report(e, StackTrace.current); // bad cache → local times
      }
    }

    final basePoints = <String, int>{};
    if (res is Map && res['checklist'] is List) {
      for (final e in res['checklist'] as List) {
        if (e is Map && e['prayer_name'] is String) {
          basePoints[e['prayer_name'] as String] = (e['points'] as num?)?.toInt() ?? 0;
        }
      }
    }

    checklist.value = [
      for (final key in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
        PrayerChecklistItem(
          prayerName: key,
          points: basePoints[key] ?? 0,
          pointsEarned: 0,
          isCompleted: false,
          time: _timeFor(key, times),
        ),
    ];
    pointsToday.value = 0;
  }

  /// Applies a `/prayers/today` response (live or cached) to the checklist.
  void _applyToday(Map<String, dynamic> res, PrayerTimes times) {
    checklist.value = (res['checklist'] as List)
        .map((e) => PrayerChecklistItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .map((item) => item.copyWith(time: _timeFor(item.prayerName, times)))
        .toList();
    pointsToday.value = (res['points_today'] as num?)?.toInt() ?? 0;
    forgotToMarkUsed.value = res['forgot_to_mark_used'] == true;
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _prayerDate(String prayerName) {
    final now = DateTime.now();
    final isBeforeFajr = now.isBefore(_adhan.getTodayPrayerTimes().fajr);
    return isBeforeFajr ? _formatDate(now.subtract(const Duration(days: 1))) : _formatDate(now);
  }

  DateTime? _timeFor(String prayerName, PrayerTimes t) {
    switch (prayerName) {
      case 'fajr':
        return t.fajr;
      case 'dhuhr':
        return t.dhuhr;
      case 'asr':
        return t.asr;
      case 'maghrib':
        return t.maghrib;
      case 'isha':
        return t.isha;
      default:
        return null;
    }
  }
}
