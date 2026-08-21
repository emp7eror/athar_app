import 'package:get/get.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';

class LeaderboardController extends GetxController {
  final _api = Get.find<ApiProvider>();
  final _store = Get.find<StorageProvider>();

  final rankings = <LeaderboardEntry>[].obs;
  final me = Rxn<LeaderboardEntry>();
  final tab = 'points'.obs; // points | streak
  // Rolling window applied to the leaderboard. Restored from storage so the
  // choice survives navigation, tab switches, and app restarts.
  final period = 'all'.obs; // all | 7d | 30d
  final scope = 'global'.obs; // all | 7d | 30d
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    period.value = _store.leaderboardPeriod;
    scope.value = _store.leaderboardScope;
    load();
  }

  void switchTab(String t) {
    if (tab.value == t) return;
    tab.value = t;
    load();
  }

  void switchPeriod(String p) {
    if (period.value == p) return;
    period.value = p;
    _store.leaderboardPeriod = p;
    load();
  }

void switchScope(String p) {
    if (scope.value == p) return;
    scope.value = p;
    _store.leaderboardScope = p;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final res = await _api.leaderboard(tab: tab.value,scope: scope.value, period: period.value);
      rankings.value =
          (res['rankings'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
      me.value = res['me'] is Map ? LeaderboardEntry.fromJson(res['me']) : null;
    } on ApiException catch (e) {
      AppSnackbar.error('leaderboard'.tr, e.message);
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([load()]);
  }
}
