import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Custom brand colors that don't map cleanly onto Material's [ColorScheme].
///
/// Access from any widget via `Theme.of(context).extension<AtharPalette>()!`
/// or the `context.athar` getter below. Light & dark variants are provided so
/// widgets never need to branch on brightness themselves.
@immutable
class AtharPalette extends ThemeExtension<AtharPalette> {
  const AtharPalette({
    required this.gold,
    required this.sage,
    required this.beige,
    required this.card,
    required this.primaryDark,
    required this.textMuted,
    required this.success,
    required this.heroGradient,
  });

  final Color gold; // Soft Gold — high-impact accents
  final Color sage; // Sage Green — subtle status / success
  final Color beige; // section surface (beige in light, deep green in dark)
  final Color card; // raised surface (white in light, elevated green in dark)
  final Color primaryDark; // deep emerald shade for gradients
  final Color textMuted; // secondary text
  final Color success; // completed / positive states
  final Gradient heroGradient; // emerald hero-card gradient

  static const light = AtharPalette(
    gold: AppColors.secondary,
    sage: AppColors.sage,
    beige: AppColors.surface,
    card: Colors.white,
    primaryDark: AppColors.primaryDark,
    textMuted: AppColors.textMuted,
    success: AppColors.success,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryDark],
    ),
  );

  static const dark = AtharPalette(
    gold: AppColors.secondary,
    sage: AppColors.sage,
    beige: Color(0xFF1E2C24), // deep green section surface
    card: Color(0xFF243329), // elevated green surface
    primaryDark: Color(0xFF0A4D36),
    textMuted: Color(0xFF97A69C),
    success: Color(0xFF3BA776),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF127E58), Color(0xFF0A4D36)],
    ),
  );

  @override
  AtharPalette copyWith({
    Color? gold,
    Color? sage,
    Color? beige,
    Color? card,
    Color? primaryDark,
    Color? textMuted,
    Color? success,
    Gradient? heroGradient,
  }) {
    return AtharPalette(
      gold: gold ?? this.gold,
      sage: sage ?? this.sage,
      beige: beige ?? this.beige,
      card: card ?? this.card,
      primaryDark: primaryDark ?? this.primaryDark,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AtharPalette lerp(ThemeExtension<AtharPalette>? other, double t) {
    if (other is! AtharPalette) return this;
    return AtharPalette(
      gold: Color.lerp(gold, other.gold, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      beige: Color.lerp(beige, other.beige, t)!,
      card: Color.lerp(card, other.card, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
    );
  }
}

/// Convenience accessors so views read `context.athar.gold` etc.
extension AtharThemeX on BuildContext {
  AtharPalette get athar => Theme.of(this).extension<AtharPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Central theme factory for the Athar app.
abstract final class AppTheme {
  static const _radius = 20.0;

  // ── Public entry points ──────────────────────────────────────────
  static ThemeData get light => _build(
        scheme: _lightScheme,
        scaffold: AppColors.bg,
        palette: AtharPalette.light,
        onColor: AppColors.textDark,
      );

  static ThemeData get dark => _build(
        scheme: _darkScheme,
        scaffold: const Color(0xFF15201A),
        palette: AtharPalette.dark,
        onColor: const Color(0xFFF1EDE4),
      );

  // ── Color schemes ────────────────────────────────────────────────
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textDark,
    tertiary: AppColors.sage,
    onTertiary: AppColors.textDark,
    surface: AppColors.surface,
    onSurface: AppColors.textDark,
    surfaceContainerLowest: Colors.white,
    surfaceContainerHighest: AppColors.surface,
    error: AppColors.danger,
    onError: Colors.white,
    outline: Color(0xFFE3D8C4),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF2E9E74), // brighter emerald for contrast on dark
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Color(0xFF1E1E1E),
    tertiary: AppColors.sage,
    onTertiary: Color(0xFF15201A),
    surface: Color(0xFF1E2C24),
    onSurface: Color(0xFFF1EDE4),
    surfaceContainerLowest: Color(0xFF243329),
    surfaceContainerHighest: Color(0xFF1E2C24),
    error: Color(0xFFE07A63),
    onError: Color(0xFF15201A),
    outline: Color(0xFF33453A),
  );

  // ── Shared builder ───────────────────────────────────────────────
  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffold,
    required AtharPalette palette,
    required Color onColor,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      extensions: [palette],
      textTheme: _textTheme(base.textTheme, onColor),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: onColor,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : palette.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.tajawal(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : palette.textMuted,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.card,
        side: BorderSide(color: scheme.outline),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.primaryDark,
        contentTextStyle: GoogleFonts.tajawal(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
    );
  }

  /// Typography: Amiri for elegant Arabic display headings, Tajawal for the
  /// UI body (supports Arabic + Latin). [onColor] flips text for dark mode.
  static TextTheme _textTheme(TextTheme base, Color onColor) {
    final body = GoogleFonts.tajawalTextTheme(base);
    return body
        .copyWith(
          displayLarge: GoogleFonts.amiri(fontSize: 40, fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.amiri(fontSize: 32, fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.w700),
          titleLarge: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w700),
          bodyLarge: GoogleFonts.tajawal(fontSize: 16, height: 1.5),
          bodyMedium: GoogleFonts.tajawal(fontSize: 14, height: 1.5),
          labelLarge: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700),
        )
        .apply(bodyColor: onColor, displayColor: onColor);
  }
}
