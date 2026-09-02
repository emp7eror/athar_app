import 'package:get/get.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/prayer_insights_model.dart';
import '../../data/providers/api_provider.dart';
import '../shell/shell_view.dart';

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
  final insights = Rxn<PrayerInsights>();

  String get _tz => DateTime.now().timeZoneName;

  @override
  void onInit() {
    super.onInit();
    load();
    _autoLoadInsightsOnVisit();
  }

  /// [StatsController] is created immediately when the app opens — GetX's
  /// `IndexedStack`-backed tab shell builds every tab's widget eagerly
  /// regardless of which one is selected, so `onInit` alone can't tell
  /// "app just opened" apart from "user is actually looking at this page".
  /// Insights are only fetched once the Stats tab is genuinely selected —
  /// immediately if that's already true, otherwise the first time it becomes
  /// true — not on every app open.
  void _autoLoadInsightsOnVisit() {
    final shell = Get.find<ShellController>();
    if (shell.index.value == ShellController.statsTabIndex) {
      _loadInsights();
    }
    ever<int>(shell.index, (i) {
      if (i == ShellController.statsTabIndex && insights.value == null) {
        _loadInsights();
      }
    });
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
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      AppSnackbar.error('stats'.tr, e.message);
    } finally {
      loading.value = false;
    }
  }

  /// Fetched separately from [load] — a failure here shouldn't block the
  /// rest of the Analytics page, so it's non-critical like [_loadQuote] on
  /// the Home screen.
  Future<void> _loadInsights() async {
    try {
      final res = await _api.statsInsights(_tz);
      insights.value = PrayerInsights.fromJson(res);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    }
  }

  /// Pull-to-refresh — an explicit user action, so unlike the auto-load on
  /// first visit, this always refreshes insights too.
  Future<void> refreshAll() async {
    await Future.wait([load(), _loadInsights()]);
  }
}
