import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/level_progress_card.dart';
import 'stats_controller.dart';
import '../../core/tour/tour_widgets.dart';
import '../tour/app_tours.dart';

class StatsView extends GetView<StatsController> {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Obx(() => controller.loading.value
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  // Keeps the whole page built so tour steps can scroll to any card.
                  scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
                  children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('stats'.tr,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      const TourHelpButton(pageId: TourPages.stats),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TourTarget(id: TourTargets.statsSummary, child: _statsRow(context)),
                  const SizedBox(height: 16),
                  TourTarget(
                    id: TourTargets.statsLevel,
                    child: LevelProgressCard(level: _cachedUser()?.level),
                  ),
                  const SizedBox(height: 24),
                   Text('last_7_days'.tr, style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TourTarget(
                    id: TourTargets.statsWeekly,
                    child: SizedBox(height: 200, child: _weeklyChart()),
                  ),
                  const SizedBox(height: 24),
                   Text('thirty_day_per_prayer'.tr, style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TourTarget(
                    id: TourTargets.statsMonthly,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  ...controller.monthly.map((m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          SizedBox(width: 90, child: Text((m['prayer_name'] as String).tr)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ((m['avg_percent'] ?? 0) as num) / 100,
                                minHeight: 10,
                                backgroundColor: Theme.of(context).colorScheme.outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${m['avg_percent']}%'),
                        ]),
                      )),
                  ]),
                  ),
                ])),
        ),
      ),
    );
  }

  /// The `/stats` endpoint doesn't carry level/monthly-score data, so this
  /// (moved here from the Profile page) reads the same cached user object
  /// the rest of the app already keeps up to date via [StorageProvider].
  UserModel? _cachedUser() {
    final u = Get.find<StorageProvider>().cachedUser;
    return u != null ? UserModel.fromJson(u) : null;
  }

  Widget _statsRow(BuildContext context) {
    final u          = _cachedUser();
    final isAr       = Get.locale?.languageCode == 'ar';
    final levelTitle = isAr ? u?.level?.titleAr : u?.level?.titleEn;
    return Column(children: [
      Row(children: [
        _statChip(context, Icons.star,                 '${u?.totalPoints ?? 0}',    'points'.tr),
        const SizedBox(width: 10),
        _statChip(context, Icons.local_fire_department,'${u?.currentStreak ?? 0}',  'streak'.tr),
        const SizedBox(width: 10),
        _statChip(context, Icons.emoji_events,          levelTitle ?? '-',           'level'.tr),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statChip(context, Icons.calendar_month,        '${u?.score ?? 0}',         'current_month_score'.tr),
        const SizedBox(width: 10),
        _statChip(context, Icons.history,                '${u?.lastScore ?? 0}',    'last_month_score'.tr),
        const SizedBox(width: 10),
        _statChip(context, Icons.military_tech,          '${u?.bestScore ?? 0}',    'best_score'.tr),
      ]),
    ]);
  }

  Widget _statChip(BuildContext context, IconData icon, String value, String label) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
            color: colors.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: colors.secondary, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),

          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _weeklyChart() {
    final data = controller.weekly;
    return BarChart(BarChartData(
      maxY: 100,
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              final d = data[i].date;
              return Text(d.substring(d.length - 2), style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: [
        for (int i = 0; i < data.length; i++)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: data[i].percent.toDouble(),
              color: AppColors.primary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ]),
      ],
    ));
  }
}
