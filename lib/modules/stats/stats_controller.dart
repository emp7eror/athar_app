import 'package:get/get.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
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

  /// Quran reading totals (pages, minutes, words, letters); null until loaded.
  final quran = Rxn<Map<String, dynamic>>();

  /// How the last 30 days' prayers were performed (congregation and mosque
  /// rates); null until loaded.
  final quality = Rxn<Map<String, dynamic>>();

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
      final q = res['quran'];
      quran.value = q is Map ? Map<String, dynamic>.from(q) : null;
      final quality = res['quality'];
      this.quality.value = quality is Map ? Map<String, dynamic>.from(quality) : null;
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      AppSnackbar.error('stats'.tr, e.message);
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([load()]);
  }
}
