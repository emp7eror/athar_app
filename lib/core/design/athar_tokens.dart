import 'package:flutter/widgets.dart';

/// Spacing scale. Every gap and inset in the app comes from here — no ad-hoc
/// numbers — so rhythm stays even across screens.
abstract final class AtharSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Side inset of a screen's content.
  static const double screen = 20;
}

/// Corner radii: small for controls, larger as surfaces grow.
abstract final class AtharRadius {
  /// Icon tiles, small badges.
  static const double sm = 10;

  /// Buttons, inputs, segmented controls.
  static const double md = 12;

  /// Cards and grouped lists.
  static const double card = 16;

  /// Hero surfaces.
  static const double lg = 20;

  /// Bottom sheets and dialogs.
  static const double sheet = 24;

  static const double pill = 999;
}

/// Motion: short and calm. Nothing bounces.
abstract final class AtharMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const emphasis = Duration(milliseconds: 450);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// Fixed sizes shared by components.
abstract final class AtharSize {
  static const double iconSm = 16;
  static const double icon = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  /// The smallest comfortable touch target.
  static const double tap = 48;

  /// The square tile an icon sits in at the start of a row.
  static const double iconTile = 36;
}
