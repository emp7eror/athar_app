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
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('leaderboard'.tr,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _periodBtn(context, 'current_month', 'leaderboard_current_month'.tr),
                  _periodBtn(context, 'all', 'leaderboard_all_time'.tr),
                ],
              ),
            )),
            const SizedBox(height: 4),
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _scopeBtn(context, 'global',  'leaderboard_global'.tr),
                  _scopeBtn(context, 'friends', 'leaderboard_friends'.tr),
                ],
              ),
            )),
            const SizedBox(height: 4),
            Expanded(
              child: Obx(() {
                // Show a spinner only on the initial load (empty list). On
                // subsequent reloads keep the old rows visible + dimmed to
                // avoid a jarring flicker when switching filters.
                if (controller.loading.value && controller.rankings.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Opacity(
                  opacity: controller.loading.value ? 0.5 : 1,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.rankings.length,
                    itemBuilder: (_, i) => _row(controller.rankings[i], isAr),
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _periodBtn(BuildContext context, String key, String label) {
    final selected = controller.period.value == key;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selectedColor: colors.primary.withValues(alpha: 0.18),
        side: BorderSide(
          color: selected ? colors.primary : colors.outline.withValues(alpha: 0.4),
        ),
        labelStyle: TextStyle(
          color: selected ? colors.primary : colors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        visualDensity: VisualDensity.compact,
        onSelected: (_) => controller.switchPeriod(key),
      ),
    );
  }
  Widget _scopeBtn(BuildContext context, String key, String label) {
    final selected = controller.scope.value == key;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selectedColor: colors.primary.withValues(alpha: 0.18),
        side: BorderSide(
          color: selected ? colors.primary : colors.outline.withValues(alpha: 0.4),
        ),
        labelStyle: TextStyle(
          color: selected ? colors.primary : colors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        visualDensity: VisualDensity.compact,
        onSelected: (_) => controller.switchScope(key),
      ),
    );
  }

  Widget _row(LeaderboardEntry e, bool isAr) {
    final isMe   = e.id == myId;
    final metric = '${e.score}';
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
