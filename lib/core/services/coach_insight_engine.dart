import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/prayer_insights_model.dart';

enum CoachTone { positive, warning, info }

class CoachInsight {
  final IconData icon;
  final CoachTone tone;
  final String title;
  final String message;

  CoachInsight({required this.icon, required this.tone, required this.title, required this.message});
}

/// Turns the numeric [PrayerInsights] payload into a short, prioritized list
/// of worded coaching cards. Pure/stateless — every rule only fires when the
/// underlying numbers clear a real threshold, so the result reflects this
/// specific user's actual last 30 days rather than generic filler advice.
class CoachInsightEngine {
  static const _weakPrayerRateCeiling = 60;
  static const _weakPrayerGap = 20;
  static const _punctualityFloor = 50;
  static const _punctualityMinCompletion = 60;

  static List<CoachInsight> build(
    PrayerInsights d, {
    required int currentStreak,
    required int maxStreak,
  }) {
    if (d.insufficientData) {
      return [
        CoachInsight(
          icon: Icons.hourglass_bottom_rounded,
          tone: CoachTone.info,
          title: 'coach_card_focus'.tr,
          message: 'coach_insufficient_data'.tr,
        ),
      ];
    }

    final insights = <CoachInsight>[];

    // 1. Trend — how this month is moving.
    insights.add(_trendInsight(d));

    // 2. Strength — always one positive note, even in a rough month.
    if (d.bestPrayer != null) {
      final best = d.perPrayer.firstWhereOrNull((p) => p.prayerName == d.bestPrayer);
      if (best != null && best.completionRate > 0) {
        insights.add(CoachInsight(
          icon: Icons.emoji_events_rounded,
          tone: CoachTone.positive,
          title: 'coach_card_strength'.tr,
          message: 'coach_strength'.trParams({
            'prayer': best.prayerName.tr,
            'rate': '${best.completionRate}',
          }),
        ));
      }
    }

    // 3. Weakest prayer — only if it's genuinely low AND meaningfully behind
    // the best prayer (otherwise every month would trigger this on noise).
    if (d.weakestPrayer != null) {
      final weak = d.perPrayer.firstWhereOrNull((p) => p.prayerName == d.weakestPrayer);
      final best = d.perPrayer.firstWhereOrNull((p) => p.prayerName == d.bestPrayer);
      if (weak != null &&
          best != null &&
          weak.prayerName != best.prayerName &&
          weak.completionRate < _weakPrayerRateCeiling &&
          (best.completionRate - weak.completionRate) >= _weakPrayerGap) {
        insights.add(CoachInsight(
          icon: Icons.trending_down_rounded,
          tone: CoachTone.warning,
          title: 'coach_card_focus'.tr,
          message: 'coach_weak_prayer'.trParams({
            'prayer': weak.prayerName.tr,
            'rate': '${weak.completionRate}',
            'tip': _tipFor(weak.prayerName),
          }),
        ));
      } else if (d.overallOnTimeRate < _punctualityFloor &&
          d.overallCompletionRate >= _punctualityMinCompletion) {
        // Only shown when the weak-prayer card didn't already fire — avoids
        // stacking two "focus area" cards in one pass.
        insights.add(CoachInsight(
          icon: Icons.schedule_rounded,
          tone: CoachTone.warning,
          title: 'coach_card_punctuality'.tr,
          message: 'coach_punctuality'.trParams({'rate': '${d.overallOnTimeRate}'}),
        ));
      }
    }

    // 4. One pattern card — weekday pattern takes priority over a missed
    // reason since it's a more specific, actionable finding.
    if (d.notableWeekday != null) {
      insights.add(CoachInsight(
        icon: Icons.calendar_view_week_rounded,
        tone: CoachTone.warning,
        title: 'coach_card_pattern'.tr,
        message: 'coach_weekday'.trParams({'weekday': _weekdayName(d.notableWeekday!)}),
      ));
    } else if (d.topMissedReason != null) {
      final key = 'coach_reason_${d.topMissedReason}';
      insights.add(CoachInsight(
        icon: Icons.psychology_alt_rounded,
        tone: CoachTone.warning,
        title: 'coach_card_pattern'.tr,
        message: key.tr,
      ));
    }

    // 5. Streak — encouragement either way.
    if (currentStreak >= 3) {
      insights.add(CoachInsight(
        icon: Icons.local_fire_department_rounded,
        tone: CoachTone.positive,
        title: 'coach_card_streak'.tr,
        message: 'coach_streak_active'.trParams({'days': '$currentStreak'}),
      ));
    } else if (currentStreak == 0 && maxStreak >= 3) {
      insights.add(CoachInsight(
        icon: Icons.replay_rounded,
        tone: CoachTone.info,
        title: 'coach_card_streak'.tr,
        message: 'coach_streak_broken'.trParams({'days': '$maxStreak'}),
      ));
    }

    return insights;
  }

  static CoachInsight _trendInsight(PrayerInsights d) {
    final from = d.trendFirstHalfRate;
    final to = d.trendSecondHalfRate;
    switch (d.trendDirection) {
      case 'improving':
        return CoachInsight(
          icon: Icons.trending_up_rounded,
          tone: CoachTone.positive,
          title: 'coach_card_trend'.tr,
          message: 'coach_trend_improving'.trParams({'from': '$from', 'to': '$to'}),
        );
      case 'declining':
        return CoachInsight(
          icon: Icons.trending_down_rounded,
          tone: CoachTone.warning,
          title: 'coach_card_trend'.tr,
          message: 'coach_trend_declining'.trParams({'from': '$from', 'to': '$to'}),
        );
      default:
        final rate = d.overallCompletionRate;
        final high = rate >= 70;
        return CoachInsight(
          icon: high ? Icons.verified_rounded : Icons.insights_rounded,
          tone: high ? CoachTone.positive : CoachTone.info,
          title: 'coach_card_trend'.tr,
          message: (high ? 'coach_trend_steady_high' : 'coach_trend_steady_low')
              .trParams({'rate': '$rate'}),
        );
    }
  }

  static String _tipFor(String prayerName) => 'coach_tip_$prayerName'.tr;

  /// [carbonWeekday] is 0=Sunday..6=Saturday (matches the backend's
  /// `Carbon::dayOfWeek`). Jan 7 2024 was a Sunday, so offsetting from it
  /// gives the right day-of-week without juggling Dart's different
  /// (1=Monday..7=Sunday) numbering.
  static String _weekdayName(int carbonWeekday) {
    final date = DateTime(2024, 1, 7 + carbonWeekday);
    final locale = Get.locale?.languageCode ?? 'en';
    return DateFormat.EEEE(locale).format(date);
  }
}
