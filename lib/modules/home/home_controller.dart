import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:athar/modules/home/missed_prayer_dialog.dart';
import 'package:athar/modules/home/prayer_confirm_dialog.dart';
import 'package:athar/modules/home/prayer_done_dialog.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';

import '../../core/services/adhan_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/sound_service.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/prayer_log_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';

class HomeController extends GetxController {
  final _api = Get.find<ApiProvider>();
  final _adhan = Get.find<AdhanService>();
  final _location = Get.find<LocationService>();
  final _sound = Get.find<SoundService>();
  final _scheduler = Get.find<PrayerNotificationScheduler>();
  final StorageProvider _storage = Get.find<StorageProvider>();

  final checklist = <PrayerChecklistItem>[].obs;
  final pointsToday = 0.obs;
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

  Future<String> get _tz async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    return timezone.identifier;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    _refreshLocationLabel();
    _startCountdown();
    refreshAll();
  }

  Future<void> refreshAll() async {
    loading.value = true;
    await Future.wait([_loadToday(), _loadQuote()]);
    loading.value = false;
  }

  Future<void> _loadToday() async {
    try {
      final tz = await _tz;
      final now = DateTime.now();
      final isBeforeFajr = now.isBefore(_adhan.getTodayPrayerTimes().fajr);

      // قبل الفجر → اجلب أمس، غير ذلك → اليوم
      final date = isBeforeFajr ? _formatDate(now.subtract(const Duration(days: 1))) : null;
      final times = isBeforeFajr ? _adhan.getTodayPrayerTimes(date: now.subtract(const Duration(days: 1))) : _adhan.getTodayPrayerTimes();

      final res = await _api.todayPrayers(tz, date: date);
      checklist.value = (res['checklist'] as List)
          .map((e) => PrayerChecklistItem.fromJson(e as Map<String, dynamic>))
          .map((item) => item.copyWith(time: _timeFor(item.prayerName, times))) // ← أضف الوقت
          .toList();
      pointsToday.value = res['points_today'] ?? 0;
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      AppSnackbar.error('app_name'.tr, e.message);
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
      await _loadToday();
      // Motivational feedback shown only AFTER the API save + reload succeed.
      await PrayerDoneDialog.showOnTime();
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
    final result = await MissedPrayerDialog.show(item.prayerName);
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
        performedOutsideTime: true,
        reason: result.reason.name,
        note: result.note.isEmpty ? null : result.note,
      );

      totalPoints.value = res['total_points'] ?? totalPoints.value;
      if (res['level'] is Map) level.value = LevelInfo.fromJson(res['level']);
      try {
        await _sound.playPrayerDone();
      } catch (e) {ErrorReporter.report(e, StackTrace.current);
      }
      await _loadToday(); // reactive checklist now shows it as done + outside-time
      await PrayerDoneDialog.showOutsideTime();
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

  void _loadUserInfo() {
    final u = Get.find<StorageProvider>().cachedUser;
    userName.value = (u?['name'] as String?) ?? '';
    avatarUrl.value = (u?['avatar_url'] as String?) ?? '';
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
