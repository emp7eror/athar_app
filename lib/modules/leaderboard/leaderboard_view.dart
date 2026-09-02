import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localization_controller.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/framed_avatar.dart';
import '../profile_preview/profile_preview_modal.dart';
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
            // Primary axis — what the ranking is based on.
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tabBtn(context, 'points', 'points_tab'.tr, Icons.star_rounded),
                  _tabBtn(context, 'streak', 'streaks_tab'.tr, Icons.local_fire_department_rounded),
                ],
              ),
            )),
            const SizedBox(height: 8),
            // Secondary refinements. Period only affects the points ranking —
            // streaks are always all-time on the backend — so it's hidden
            // rather than shown as a no-op while the streak tab is active.
            Obx(() => AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: controller.tab.value == 'streak'
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _periodBtn(context, 'current_month', 'leaderboard_current_month'.tr, Icons.calendar_month_rounded),
                          _periodBtn(context, 'all', 'leaderboard_all_time'.tr, Icons.all_inclusive_rounded),
                        ],
                      ),
                    ),
            )),
            const SizedBox(height: 4),
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _scopeBtn(context, 'global',  'leaderboard_global'.tr, Icons.public_rounded),
                  _scopeBtn(context, 'friends', 'leaderboard_friends'.tr, Icons.people_alt_rounded),
                ],
              ),
            )),
            const SizedBox(height: 4),
            const Divider(height: 1, indent: 16, endIndent: 16),
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
                    itemBuilder: (_, i) => _row(
                      controller.rankings[i],
                      isAr,
                      controller.tab.value == 'streak' ? _Metric.streak
                          : controller.period.value == 'all' ? _Metric.totalPoints
                          : _Metric.score,
                    ),
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tabBtn(BuildContext context, String key, String label, IconData icon) => _chip(
    context: context,
    selected: controller.tab.value == key,
    icon: icon,
    label: label,
    onTap: () => controller.switchTab(key),
  );

  Widget _periodBtn(BuildContext context, String key, String label, IconData icon) => _chip(
    context: context,
    selected: controller.period.value == key,
    icon: icon,
    label: label,
    onTap: () => controller.switchPeriod(key),
  );

  Widget _scopeBtn(BuildContext context, String key, String label, IconData icon) => _chip(
    context: context,
    selected: controller.scope.value == key,
    icon: icon,
    label: label,
    onTap: () => controller.switchScope(key),
  );

  /// Shared chip styling for all three filter rows (tab / period / scope).
  Widget _chip({
    required BuildContext context,
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        avatar: Icon(icon, size: 15, color: selected ? colors.primary : colors.onSurfaceVariant),
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
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _row(LeaderboardEntry e, bool isAr, _Metric metric) {
    final isMe   = e.id == myId;
    final value = switch (metric) {
      _Metric.streak      => e.currentStreak,
      _Metric.totalPoints => e.totalPoints,
      _Metric.score       => e.score,
    };
    final metricIcon = metric == _Metric.streak ? Icons.local_fire_department_rounded : Icons.star_rounded;
    final title = e.level == null ? '' : e.level!.displayName(isAr);
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
          onTap: () => openProfilePreview(e.id, rank: e.rank),
          leading: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FramedAvatar(
                  name: e.name,
                  avatarUrl: e.avatarUrl,
                  frameAsset: e.level?.frame,
                  radius: 20,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: e.rank <= 3 ? AppColors.accent : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text('${e.rank}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          title: Text(e.name),
          subtitle: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 4),

              Transform.translate(
                offset: const Offset(0, -3),
                child: Icon(
                  metricIcon,
                  size: 17,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which number the leaderboard row's trailing value shows — driven by the
/// tab (points vs streak) and, for points, the period (month vs all-time).
enum _Metric { score, totalPoints, streak }
