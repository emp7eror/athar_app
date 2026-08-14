import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import 'stats_controller.dart';

class StatsView extends GetView<StatsController> {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Obx(() => controller.loading.value
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(16), children: [
                Text('stats'.tr,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  _stat('🔥', '${controller.currentStreak.value}', 'streak'.tr),
                  _stat('🏆', '${controller.maxStreak.value}', 'max'),
                  _stat('⭐', '${controller.totalPoints.value}', 'points'.tr),
                ]),
                const SizedBox(height: 24),
                const Text('Last 7 days', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(height: 200, child: _weeklyChart()),
                const SizedBox(height: 24),
                const Text('30-day per-prayer', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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
                              backgroundColor: AppColors.card,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${m['avg_percent']}%'),
                      ]),
                    )),
              ])),
      ),
    );
  }

  Widget _stat(String icon, String value, String label) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration:
              BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ),
      );

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
