import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Single source of truth for the four visual states the prayer tile can be
/// in. Every tile element (background, border, name, time, icon, points pill)
/// resolves its color through this enum so a designer only has to touch one
/// place to retune the palette.
enum PrayerVisualTheme {
  /// Distant future prayer, before its window and not the "next" one — keeps
  /// the default card look so the tile doesn't shout.
  neutral,

  /// Currently active OR the next-up prayer — muted green highlight.
  upcoming,

  /// Completed within its scheduled window (no bonus).
  onTime,

  /// Special/priority state: either completed within the first 30 min
  /// (bonus earned) or currently inside the bonus preview window.
  bonus,

  /// Missed (past-window + not logged) OR completed as Qada after the
  /// window closed — warm amber/orange.
  missed,
  late,
}

/// Resolves a single [PrayerVisualTheme] from the booleans the tile already
/// computes. Precedence (top wins) matches the product spec:
///
///   done+bonusEarned  ─▶ bonus
///   done+late         ─▶ missed  (Qada)
///   done              ─▶ onTime
///   missed            ─▶ missed  (yet-to-log)
///   active+bonusPeek  ─▶ bonus   (preview / encouragement)
///   active            ─▶ upcoming
///   isNextUpcoming    ─▶ upcoming
///   else              ─▶ neutral
PrayerVisualTheme resolvePrayerVisualTheme({
  required bool done,
  required bool late,
  required bool bonusEarned,
  required bool bonusAvailable,
  required bool missed,
  required bool active,
  required bool isNextUpcoming,
}) {
  if (done && bonusEarned) return PrayerVisualTheme.bonus;
  if (done && late) return PrayerVisualTheme.onTime;
  if (done) return PrayerVisualTheme.onTime;
  if (missed) return PrayerVisualTheme.missed;
  if (active && bonusAvailable) return PrayerVisualTheme.bonus;
  if (active) return PrayerVisualTheme.upcoming;
  if (isNextUpcoming) return PrayerVisualTheme.upcoming;
  return PrayerVisualTheme.neutral;
}

/// Themed color for the resolved state. Every tile element pulls from the
/// same accent so shifting the palette is a one-line change.
extension PrayerVisualThemeColors on PrayerVisualTheme {
  Color accent(BuildContext context) {
    final p = context.athar;
    switch (this) {
      case PrayerVisualTheme.bonus:
        return p.gold;
        case PrayerVisualTheme.late:
        return p.gold;
      case PrayerVisualTheme.missed:
        return p.danger;
      case PrayerVisualTheme.onTime:
      case PrayerVisualTheme.upcoming:
        return p.success;
      case PrayerVisualTheme.neutral:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Whether this state should tint the row background/border, or keep the
  /// default card look. Neutral (distant future) tiles stay uncolored to
  /// avoid stacking multiple green rows in the daily list.
  bool get tintsRow => this != PrayerVisualTheme.neutral;
}
