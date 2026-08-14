import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:get/get.dart';
import '../../core/services/adhan_service.dart';
import '../../data/providers/api_provider.dart';
import '../../data/models/prayer_log_model.dart';
import '../../data/models/user_model.dart';

class HomeController extends GetxController {
  final _api = Get.find<ApiProvider>();
  final _adhan = Get.find<AdhanService>();

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

  Timer? _ticker;
  String get _tz => DateTime.now().timeZoneName;

  @override
  void onInit() {
    super.onInit();
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
      final res = await _api.todayPrayers(_tz);
      checklist.value = (res['checklist'] as List)
          .map((e) => PrayerChecklistItem.fromJson(e))
          .toList();
      pointsToday.value = res['points_today'] ?? 0;
    } on ApiException catch (e) {
      Get.snackbar('app_name'.tr, e.message);
    }
  }

  Future<void> _loadQuote() async {
    try {
      final q = await _api.randomQuote();
      quote.value = q['text'] ?? '';
      quoteSource.value = q['source'] ?? '';
    } catch (_) {/* non-critical */}
  }

  /// Local window check gates the checkbox before we ever hit the API.
  bool isActive(String prayerKey) {
    final p = Prayer.values.firstWhere((e) => e.name == prayerKey, orElse: () => Prayer.fajr);
    return _adhan.isPrayerTimeActive(p);
  }

  Future<void> mark(PrayerChecklistItem item) async {
    if (item.isCompleted) return; // one-way completion from the UI
    if (!isActive(item.prayerName)) {
      Get.snackbar('app_name'.tr, 'window_closed'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    marking.value = item.prayerName;
    try {
      final res = await _api.markPrayer(item.prayerName, completed: true, tz: _tz);
      totalPoints.value = res['total_points'] ?? totalPoints.value;
      if (res['level'] is Map) level.value = LevelInfo.fromJson(res['level']);
      await _loadToday();
      Get.snackbar('+${item.points}', 'points'.tr,
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
    } on ApiException catch (e) {
      Get.snackbar('app_name'.tr, e.message, snackPosition: SnackPosition.BOTTOM);
    } finally {
      marking.value = '';
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
}
