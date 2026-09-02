import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_theme.dart';
import '../data/models/user_model.dart';

/// Current level + progress-to-next-level, shown on the Home screen and the
/// Profile page. Mirrors the achievement section already used in the
/// leaderboard's profile preview modal.
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({super.key, required this.level});

  final LevelInfo? level;

  @override
  Widget build(BuildContext context) {
    final l = level;
    final atMax = l != null && l.nextAt == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.athar.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_events_rounded, color: context.athar.gold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (l?.progress ?? 0).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  atMax
                      ? 'max_level_reached'.tr
                      : '${'progress_to_next'.tr}'
                          '${l == null ? '' : ' • ${l.pointsToNext} ${'points'.tr}'}',
                  style: TextStyle(color: context.athar.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
