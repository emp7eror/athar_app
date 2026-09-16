import 'package:flutter/material.dart';

import '../../core/ui/athar_tone.dart';

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
///   isNextUpcoming    ─▶ neutral
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
  // The next prayer wears the same colour as the ones after it; its icon,
  // label and countdown are what set it apart.
  if (isNextUpcoming) return PrayerVisualTheme.neutral;
  return PrayerVisualTheme.neutral;
}

/// Themed colour for the resolved state. Each state maps to a design-system
/// tone, so every theme preset resolves the accent its own way — the active
/// and next prayers follow the preset's brand colour rather than a fixed
/// green, and the tints below always sit on the right ground.
extension PrayerVisualThemeColors on PrayerVisualTheme {
  /// The meaning the row carries; all of its colours come from this.
  AtharTone get tone => switch (this) {
        PrayerVisualTheme.bonus || PrayerVisualTheme.late => AtharTone.gold,
        PrayerVisualTheme.missed => AtharTone.danger,
        PrayerVisualTheme.onTime => AtharTone.success,
        // Active / next — the preset's own brand colour.
        PrayerVisualTheme.upcoming => AtharTone.brand,
        PrayerVisualTheme.neutral => AtharTone.neutral,
      };

  /// Icons and text.
  Color accent(BuildContext context) => tone.foreground(context);

  /// The quiet tint behind [accent] — icon disc, points pill.
  Color accentSurface(BuildContext context) => tone.background(context);

  /// Whether this state should tint the row background/border, or keep the
  /// default card look. Neutral (distant future) tiles stay uncolored to
  /// avoid stacking multiple green rows in the daily list.
  bool get tintsRow => this != PrayerVisualTheme.neutral;
}
