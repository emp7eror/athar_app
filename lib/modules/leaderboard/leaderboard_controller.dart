import 'package:get/get.dart';
import '../../core/utils/snackbar.dart';
import '../../data/providers/api_provider.dart';
import '../../data/models/leaderboard_model.dart';

class LeaderboardController extends GetxController {
  final _api = Get.find<ApiProvider>();

  final rankings = <LeaderboardEntry>[].obs;
  final me = Rxn<LeaderboardEntry>();
  final tab = 'points'.obs; // points | streak
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void switchTab(String t) {
    if (tab.value == t) return;
    tab.value = t;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final res = await _api.leaderboard(tab: tab.value);
      rankings.value =
          (res['rankings'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
      me.value = res['me'] is Map ? LeaderboardEntry.fromJson(res['me']) : null;
    } on ApiException catch (e) {
      AppSnackbar.error('leaderboard'.tr, e.message);
    } finally {
      loading.value = false;
    }
  }
}
