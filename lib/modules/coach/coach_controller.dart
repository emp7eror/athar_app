import 'package:get/get.dart';

import '../../core/services/timezone_service.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/models/prayer_insights_model.dart';
import '../../data/providers/api_provider.dart';

/// Owns the AI coaching insights, which now live on their own page reached
/// from the Home screen rather than inside the Analytics tab.
///
/// Because this controller is created when that page opens (not eagerly with
/// the tab shell), the fetch can simply happen in [onInit] — no tab-visibility
/// watching needed like the old placement required.
class CoachController extends GetxController {
  final _api = Get.find<ApiProvider>();

  final insights = Rxn<PrayerInsights>();
  final loading = false.obs;
  final failed = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    failed.value = false;
    try {
      final tz = await Get.find<TimezoneService>().resolve();
      final res = await _api.statsInsights(tz);
      insights.value = PrayerInsights.fromJson(res);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      failed.value = true;
    } finally {
      loading.value = false;
    }
  }
}
