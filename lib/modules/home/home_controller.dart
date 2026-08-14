import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:athar/modules/home/prayer_confirm_dialog.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';

import '../../core/services/adhan_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/prayer_log_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';

class HomeController extends GetxController {
  final _api = Get.find<ApiProvider>();
  final _adhan = Get.find<AdhanService>();
  final _location = Get.find<LocationService>();

  final checklist = <PrayerChecklistItem>[].obs;
  final pointsToday = 0.obs;
  final totalPoints = 0.obs;
  final level = Rxn<LevelInfo>();
  final quote = ''.obs;
  final quoteSource = ''.obs;

  final nextPrayerKey = ''.obs;
  final countdown = '00:00:00'.obs;
  final loading = true.obs;
  final marking = ''.obs; // prayer currently being toggled
  final locationLabel = 'location_not_set'.obs;
  final updatingLocation = false.obs;

  Timer? _ticker;

  Future<String> get _tz async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    return timezone.identifier;
  }

  @override
  void onInit() {
    super.onInit();
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
      final timezone = await _tz;
      final res = await _api.todayPrayers(await timezone);
      checklist.value = (res['checklist'] as List).map((e) => PrayerChecklistItem.fromJson(e)).toList();
      pointsToday.value = res['points_today'] ?? 0;
    } on ApiException catch (e) {
      AppSnackbar.error('app_name'.tr, e.message);
    }
  }

  Future<void> _loadQuote() async {
    try {
      final q = await _api.randomQuote();
      quote.value = q['text'] ?? '';
      quoteSource.value = q['source'] ?? '';
    } catch (_) {
      /* non-critical */
    }
  }

  /// Local window check gates the checkbox before we ever hit the API.
  bool isActive(String prayerKey) {
    final p = Prayer.values.firstWhere((e) => e.name == prayerKey, orElse: () => Prayer.fajr);
    return _adhan.isPrayerTimeActive(p);
  }

  Future<void> mark(PrayerChecklistItem item) async {
    if (item.isCompleted) return;
    if (!isActive(item.prayerName)) {
      AppSnackbar.error('app_name'.tr, 'window_closed'.tr);
      return;
    }

    // ── اعرض الـ dialog أولاً ──
    final result = await PrayerConfirmDialog.show(item.prayerName, item.points);
    if (result == null) return; // المستخدم ألغى

    marking.value = item.prayerName;
    try {
      final timezone = await _tz;
      final res = await _api.markPrayer(
        item.prayerName,
        completed: true,
        tz: timezone,
        difficulty: result.difficulty.name,  // 'easy' | 'medium' | 'hard'
        mood:       result.mood.name,        // 'focused' | 'peaceful' | 'distracted' | 'tired'
        note:       result.note.isEmpty ? null : result.note,
      );
      totalPoints.value = res['total_points'] ?? totalPoints.value;
      if (res['level'] is Map) level.value = LevelInfo.fromJson(res['level']);
      await _loadToday();
      AppSnackbar.show('+${item.points} ${'points'.tr}', 'prayer_recorded'.tr);
    } on ApiException catch (e) {
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
      AppSnackbar.show('app_name'.tr, 'location_updated'.tr);
    } catch (key) {
      AppSnackbar.error('app_name'.tr, (key is String ? key : 'location_error').tr);
    } finally {
      updatingLocation.value = false;
    }
  }

  void _startCountdown() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _adhan.nextPrayer();
      nextPrayerKey.value = AdhanService.prayerKey(next.prayer);
      final diff = next.time.difference(DateTime.now());
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
      locationLabel.value = city;                       // "مكة المكرمة" or "Makkah"
    } else if (s.lat != null && s.lng != null) {
      locationLabel.value =
      '${s.lat!.toStringAsFixed(3)}, ${s.lng!.toStringAsFixed(3)}';
    }
  }
}
