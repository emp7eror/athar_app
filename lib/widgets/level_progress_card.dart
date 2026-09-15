import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/ui/athar_ui.dart';
import '../data/models/user_model.dart';

/// Current level and progress toward the next, shown on Profile and Stats.
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({super.key, required this.level});

  final LevelInfo? level;

  @override
  Widget build(BuildContext context) {
    final l = level;
    final atMax = l != null && l.nextAt == null;
    final isAr = Get.locale?.languageCode == 'ar';
    final progress = (l?.progress ?? 0).clamp(0, 1).toDouble();

    return AtharCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AtharTone.gold.background(context),
              borderRadius: BorderRadius.circular(AtharRadius.md),
            ),
            child: Icon(Icons.workspace_premium_rounded, size: 26, color: context.athar.goldText),
          ),
          const SizedBox(width: AtharSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('current_level'.tr, style: context.type.caption),
                Text(l == null ? '-' : l.displayName(isAr), style: context.type.cardTitle),
                const SizedBox(height: AtharSpace.xs),
                AtharProgressBar(
                  value: progress,
                  color: context.athar.gold,
                  semanticsLabel: 'progress_to_next'.tr,
                ),
                const SizedBox(height: AtharSpace.xs),
                Text(
                  atMax
                      ? 'max_level_reached'.tr
                      : '${'progress_to_next'.tr}${l == null ? '' : ' · ${l.pointsToNext} ${'points'.tr}'}',
                  style: context.type.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
