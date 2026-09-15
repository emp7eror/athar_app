import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Athar's type families.
///
/// IBM Plex Sans Arabic for the Arabic interface, Inter for the English one,
/// each falling back to the other for mixed text. Quran text keeps its own
/// dedicated font and never takes the interface font.
abstract final class AtharFonts {
  static const arabic = 'IBMPlexSansArabic';
  static const latin = 'Inter';
  static const quran = 'AmiriQuran';

  /// Whether the font files ship inside the app (assets/fonts, declared in
  /// pubspec.yaml). When false, the same families are fetched and cached by
  /// google_fonts instead.
  static const bundled = true;
}

/// The type scale, built for the interface language.
///
/// Arabic gets taller lines than Latin — its letters reach further above and
/// below the line — and is never letter-spaced, which breaks its joins.
abstract final class AtharTypography {
  static TextStyle _style({
    required bool arabic,
    required double size,
    required FontWeight weight,
    required double height,
    double latinSpacing = 0,
  }) {
    final spacing = arabic ? 0.0 : latinSpacing;
    if (!AtharFonts.bundled) {
      final style = arabic
          ? GoogleFonts.ibmPlexSansArabic(fontSize: size, fontWeight: weight, height: height)
          : GoogleFonts.inter(fontSize: size, fontWeight: weight, height: height, letterSpacing: spacing);
      return style.copyWith(leadingDistribution: TextLeadingDistribution.even);
    }
    return TextStyle(
      fontFamily: arabic ? AtharFonts.arabic : AtharFonts.latin,
      fontFamilyFallback: [arabic ? AtharFonts.latin : AtharFonts.arabic],
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static TextTheme textTheme({required bool arabic, required Color color}) {
    TextStyle t(double size, FontWeight weight, double latinHeight, double arabicHeight, [double spacing = 0]) =>
        _style(
          arabic: arabic,
          size: size,
          weight: weight,
          height: arabic ? arabicHeight : latinHeight,
          latinSpacing: spacing,
        ).copyWith(color: color);

    return TextTheme(
      displayLarge: t(40, FontWeight.w600, 1.12, 1.25, -0.8),
      displayMedium: t(32, FontWeight.w600, 1.15, 1.3, -0.6),
      displaySmall: t(28, FontWeight.w600, 1.2, 1.35, -0.4),
      headlineLarge: t(26, FontWeight.w700, 1.25, 1.4, -0.3),
      headlineMedium: t(24, FontWeight.w700, 1.25, 1.4, -0.3),
      headlineSmall: t(20, FontWeight.w700, 1.3, 1.45, -0.2),
      titleLarge: t(18, FontWeight.w700, 1.35, 1.5, -0.1),
      titleMedium: t(16, FontWeight.w600, 1.4, 1.55),
      titleSmall: t(14, FontWeight.w600, 1.4, 1.55),
      bodyLarge: t(16, FontWeight.w400, 1.5, 1.7),
      bodyMedium: t(14, FontWeight.w400, 1.5, 1.7),
      bodySmall: t(12.5, FontWeight.w400, 1.45, 1.6, 0.1),
      labelLarge: t(14, FontWeight.w600, 1.3, 1.4, 0.1),
      labelMedium: t(13, FontWeight.w600, 1.3, 1.4, 0.2),
      labelSmall: t(12, FontWeight.w500, 1.3, 1.4, 0.3),
    );
  }

  /// Quran text, in its dedicated font.
  static TextStyle quran({required double size, Color? color, double height = 2.0}) {
    if (!AtharFonts.bundled) {
      return GoogleFonts.amiriQuran(fontSize: size, color: color, height: height);
    }
    return TextStyle(fontFamily: AtharFonts.quran, fontSize: size, color: color, height: height);
  }
}

/// Named text roles, so screens say what a piece of text *is* rather than
/// picking sizes: `context.type.sectionTitle`, `context.type.statValue`.
class AtharType {
  const AtharType(this._theme);

  final ThemeData _theme;

  TextTheme get _t => _theme.textTheme;
  Color get _muted => _theme.colorScheme.onSurfaceVariant;

  static const _tabular = [FontFeature.tabularFigures()];

  TextStyle get display => _t.displaySmall!;
  TextStyle get screenTitle => _t.headlineSmall!;
  TextStyle get sectionTitle => _t.titleMedium!.copyWith(fontWeight: FontWeight.w700);
  TextStyle get cardTitle => _t.titleSmall!.copyWith(fontWeight: FontWeight.w700);
  TextStyle get body => _t.bodyMedium!;
  TextStyle get bodyStrong => _t.bodyMedium!.copyWith(fontWeight: FontWeight.w600);
  TextStyle get caption => _t.bodySmall!.copyWith(color: _muted);
  TextStyle get overline => _t.labelSmall!.copyWith(color: _muted);
  TextStyle get button => _t.labelLarge!;

  /// Inline figures that update in place (timers, counters): digits keep one
  /// width so the text doesn't jitter.
  TextStyle get number => _t.titleLarge!.copyWith(fontFeatures: _tabular);
  TextStyle get statValue => _t.headlineSmall!.copyWith(fontFeatures: _tabular);
  TextStyle get bigNumber => _t.displayMedium!.copyWith(fontFeatures: _tabular);
  TextStyle get prayerName => _t.titleMedium!.copyWith(fontWeight: FontWeight.w700);

  TextStyle quran({double size = 24}) =>
      AtharTypography.quran(size: size, color: _theme.colorScheme.onSurface);
}

extension AtharTypeX on BuildContext {
  AtharType get type => AtharType(Theme.of(this));
}
