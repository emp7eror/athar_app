import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/level_progress_card.dart';
import '../tour/app_tours.dart';
import 'stats_controller.dart';

/// Statistics: your totals, your level, the last week, each prayer over the
/// last month, how you prayed, and your Quran reading.
class StatsView extends GetView<StatsController> {
  const StatsView({super.key});

  /// Room under the content for the floating nav bar.
  static const _navClearance = 160.0;

  /// The `/stats` endpoint doesn't carry level or monthly-score data, so these
  /// come from the cached user the rest of the app keeps up to date.
  UserModel? _cachedUser() {
    final u = Get.find<StorageProvider>().cachedUser;
    return u != null ? UserModel.fromJson(u) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Obx(() {
            final firstLoad = controller.loading.value && controller.weekly.isEmpty;
            final user = _cachedUser();

            return ListView(
              padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, _navClearance),
              // Keeps the whole page built so tour steps can scroll to any part.
              scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
              children: [
                AtharPageHeader(
                  title: 'stats'.tr,
                  trailing: const [TourHelpButton(pageId: TourPages.stats)],
                ),
                const SizedBox(height: AtharSpace.md),
                if (firstLoad) ...const [
                  AtharSkeleton(height: 150, radius: AtharRadius.card),
                  SizedBox(height: AtharSpace.md),
                  AtharSkeleton(height: 90, radius: AtharRadius.card),
                  SizedBox(height: AtharSpace.md),
                  AtharSkeleton(height: 220, radius: AtharRadius.card),
                ] else ...[
                  TourTarget(id: TourTargets.statsSummary, child: _Summary(user: user)),
                  const SizedBox(height: AtharSpace.md),
                  TourTarget(id: TourTargets.statsLevel, child: LevelProgressCard(level: user?.level)),
                  const SizedBox(height: AtharSpace.xl),
                  AtharSectionHeader(title: 'last_7_days'.tr),
                  TourTarget(
                    id: TourTargets.statsWeekly,
                    child: AtharCard(
                      padding: const EdgeInsets.fromLTRB(AtharSpace.sm, AtharSpace.lg, AtharSpace.sm, AtharSpace.xs),
                      child: SizedBox(height: 180, child: _WeeklyChart(points: controller.weekly.toList())),
                    ),
                  ),
                  const SizedBox(height: AtharSpace.xl),
                  AtharSectionHeader(title: 'thirty_day_per_prayer'.tr),
                  TourTarget(
                    id: TourTargets.statsMonthly,
                    child: _MonthlyCard(rows: controller.monthly.toList()),
                  ),
                  const _QualitySection(),
                  const _QuranSection(),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final u = user;
    final isAr = Get.locale?.languageCode == 'ar';
    final levelTitle = isAr ? u?.level?.titleAr : u?.level?.titleEn;

    return AtharCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AtharStat(
                  icon: Icons.star_rounded,
                  // tone: AtharTone.gold,
                  value: '${u?.totalPoints ?? 0}',
                  label: 'points'.tr,
                  center: true,
                ),
              ),
              Expanded(
                child: AtharStat(
                  icon: Icons.local_fire_department_rounded,
                  // tone: AtharTone.warning,
                  value: '${u?.currentStreak ?? 0}',
                  label: 'streak'.tr,
                  center: true,
                ),
              ),
              Expanded(
                child: AtharStat(
                  icon: Icons.workspace_premium_rounded,
                  value: (levelTitle == null || levelTitle.isEmpty) ? '-' : levelTitle,
                  label: 'level'.tr,
                  center: true,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AtharSpace.md),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: AtharStat(
                  icon: Icons.calendar_month_rounded,
                  value: '${u?.score ?? 0}',
                  label: 'current_month_score'.tr,
                  center: true,
                ),
              ),
              Expanded(
                child: AtharStat(
                  icon: Icons.history_rounded,
                  // tone: AtharTone.neutral,
                  value: '${u?.lastScore ?? 0}',
                  label: 'last_month_score'.tr,
                  center: true,
                ),
              ),
              Expanded(
                child: AtharStat(
                  icon: Icons.military_tech_rounded,
                  // tone: AtharTone.gold,
                  value: '${u?.bestScore ?? 0}',
                  label: 'best_score'.tr,
                  center: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The share of prayers completed on each of the last seven days; today's bar
/// in gold.
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.points});

  final List<WeeklyPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final gold = context.athar.gold;
    final summary = points.map((p) => '${p.date.substring(p.date.length - 2)}: ${p.percent}%').join(', ');

    return Semantics(
      label: '${'last_7_days'.tr}. $summary',
      excludeSemantics: true,
      child: BarChart(
        BarChartData(
          maxY: 100,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  final d = points[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: AtharSpace.xs),
                    child: Text(d.substring(d.length - 2), style: context.type.caption),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].percent.toDouble(),
                    color: i == points.length - 1 ? gold : scheme.primary,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Each prayer's completion over the last thirty days.
class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return AtharCard(
      child: Column(
        children: [
          for (final (i, m) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: AtharSpace.sm),
            Builder(builder: (context) {
              final name = (m['prayer_name'] as String).tr;
              final percent = ((m['avg_percent'] ?? 0) as num).round();
              return Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
                  ),
                  const SizedBox(width: AtharSpace.sm),
                  Expanded(
                    child: AtharProgressBar(value: percent / 100, semanticsLabel: name),
                  ),
                  const SizedBox(width: AtharSpace.sm),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$percent%',
                      textAlign: TextAlign.end,
                      style: context.text.labelLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// How the last thirty days' prayers were performed — from the answers given
/// when marking them. Only rates the user has actually answered are shown.
class _QualitySection extends GetView<StatsController> {
  const _QualitySection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = controller.quality.value;
      if (q == null) return const SizedBox.shrink();

      final rates = [
        (Icons.groups_rounded, q['congregation_rate'], 'quality_jamaah'.tr),
        (Icons.mosque_rounded, q['mosque_rate'], 'quality_mosque'.tr),
      ].where((r) => r.$2 is num).toList();
      if (rates.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AtharSpace.xl),
          AtharSectionHeader(title: 'prayer_quality_title'.tr),
          AtharCard(
            child: Row(
              children: [
                for (final r in rates)
                  Expanded(
                    child: AtharStat(
                      icon: r.$1,
                      value: '${(r.$2 as num).round()}%',
                      label: r.$3,
                      center: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Quran reading totals. Words and letters appear once the server has the
/// per-page counts; the section hides until /stats sends it.
class _QuranSection extends GetView<StatsController> {
  const _QuranSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = controller.quran.value;
      if (q == null) return const SizedBox.shrink();

      final number = NumberFormat.decimalPattern(Get.locale?.languageCode);
      String value(String key) => number.format((q[key] as num?)?.toInt() ?? 0);

      Widget pair(AtharStat a, AtharStat b) => Row(
            children: [Expanded(child: a), Expanded(child: b)],
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AtharSpace.xl),
          AtharSectionHeader(title: 'quran_stats_title'.tr),
          AtharCard(
            child: Column(
              children: [
                pair(
                  AtharStat(icon: Icons.auto_stories_rounded, value: value('pages_read'), label: 'quran_stat_pages'.tr, center: true),
                  AtharStat(icon: Icons.timer_rounded, value: value('minutes'), label: 'quran_stat_minutes'.tr, center: true),
                ),
                if (q['word_counts_available'] == true) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AtharSpace.md),
                    child: Divider(height: 1),
                  ),
                  pair(
                    AtharStat(icon: Icons.notes_rounded, value: value('words_read'), label: 'quran_stat_words'.tr, center: true),
                    AtharStat(icon: Icons.text_fields_rounded, value: value('letters_read'), label: 'quran_stat_letters'.tr, center: true),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}
