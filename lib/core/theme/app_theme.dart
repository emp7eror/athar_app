import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Custom brand colors that don't map cleanly onto Material's [ColorScheme].
///
/// Access from any widget via `Theme.of(context).extension<AtharPalette>()!`
/// or the `context.athar` getter below.
@immutable
class AtharPalette extends ThemeExtension<AtharPalette> {
  const AtharPalette({
    required this.gold,
    required this.sage,
    required this.beige,
    required this.primaryDark,
    required this.textMuted,
    required this.success,
    required this.heroGradient,
  });

  final Color gold; // Soft Gold — high-impact accents
  final Color sage; // Sage Green — subtle status / success
  final Color beige; // Light Beige — card & divider surfaces
  final Color primaryDark; // deep emerald shade for gradients
  final Color textMuted; // secondary text
  final Color success; // completed / positive states
  final Gradient heroGradient; // emerald hero-card gradient

  static const light = AtharPalette(
    gold: AppColors.secondary,
    sage: AppColors.sage,
    beige: AppColors.surface,
    primaryDark: AppColors.primaryDark,
    textMuted: AppColors.textMuted,
    success: AppColors.success,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryDark],
    ),
  );

  @override
  AtharPalette copyWith({
    Color? gold,
    Color? sage,
    Color? beige,
    Color? primaryDark,
    Color? textMuted,
    Color? success,
    Gradient? heroGradient,
  }) {
    return AtharPalette(
      gold: gold ?? this.gold,
      sage: sage ?? this.sage,
      beige: beige ?? this.beige,
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

  static ThemeData get light {
    const scheme = ColorScheme(
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

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      extensions: const [AtharPalette.light],
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textDark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE7DCC8),
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.tajawal(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFE7DCC8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: GoogleFonts.tajawal(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3D8C4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3D8C4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }

  /// Typography: Amiri for elegant Arabic display headings, Tajawal for the
  /// UI body (supports Arabic + Latin), giving cohesive bilingual rendering.
  static TextTheme _textTheme(TextTheme base) {
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
        .apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark);
  }
}
