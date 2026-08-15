import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localization_controller.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/providers/storage_provider.dart';
import 'leaderboard_controller.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});
  int get myId =>
      (Get.find<StorageProvider>().cachedUser?['id'] as num?)?.toInt() ?? -1;

  @override
  Widget build(BuildContext context) {
    final isAr = Get.find<LocalizationController>().isRtl;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('leaderboard'.tr,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tabBtn(context, 'points', 'points_tab'.tr),
                  _tabBtn(context, 'streak', 'streaks_tab'.tr),
                ],
              )),
          Expanded(
            child: Obx(() => controller.loading.value
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.rankings.length,
                    itemBuilder: (_, i) =>
                        _row(controller.rankings[i], controller.tab.value, isAr),
                  )),
          ),
        ]),
      ),
    );
  }

  Widget _tabBtn(BuildContext context, String key, String label) {
    final selected = controller.tab.value == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface),
        onSelected: (_) => controller.switchTab(key),
      ),
    );
  }

  Widget _row(LeaderboardEntry e, String tab, bool isAr) {
    final isMe   = e.id == myId;
    final metric = tab == 'streak' ? '🔥 ${e.currentStreak}' : '${e.totalPoints}';
    final title = e.level == null ? '' : (isAr ? e.level!.titleAr : e.level!.titleEn);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: isMe
          ? BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent,
          width: 3,
        ),
      )
          : null,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: e.rank <= 3 ? AppColors.accent : AppColors.primary,
            child: Text('${e.rank}', style: const TextStyle(color: Colors.white)),
          ),
          title: Text(e.name),
          subtitle: Text(title),
          trailing: Text(metric,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
