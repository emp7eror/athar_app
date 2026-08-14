import 'package:get/get.dart';
import '../../data/providers/api_provider.dart';

class WeeklyPoint {
  final String date;
  final int completed, points, percent;
  WeeklyPoint(this.date, this.completed, this.points, this.percent);
}

class StatsController extends GetxController {
  final _api = Get.find<ApiProvider>();

  final loading = false.obs;
  final dailyPercent = 0.obs;
  final weekly = <WeeklyPoint>[].obs;
  final monthly = <Map<String, dynamic>>[].obs;
  final currentStreak = 0.obs;
  final maxStreak = 0.obs;
  final totalPoints = 0.obs;

  String get _tz => DateTime.now().timeZoneName;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final res = await _api.stats(_tz);
      dailyPercent.value = res['daily']?['percent'] ?? 0;
      weekly.value = (res['weekly'] as List)
          .map((e) => WeeklyPoint(e['date'], e['completed'] ?? 0, e['points'] ?? 0, e['percent'] ?? 0))
          .toList();
      monthly.value = List<Map<String, dynamic>>.from(res['monthly'] ?? []);
      final s = res['summary'] ?? {};
      currentStreak.value = s['current_streak'] ?? 0;
      maxStreak.value = s['max_streak'] ?? 0;
      totalPoints.value = s['total_points'] ?? 0;
    } on ApiException catch (e) {
      Get.snackbar('stats'.tr, e.message);
    } finally {
      loading.value = false;
    }
  }
}
