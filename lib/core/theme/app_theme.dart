import 'package:flutter/material.dart';

import '../design/athar_theme_presets.dart';
import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';

/// Brand colours that don't map cleanly onto Material's [ColorScheme].
///
/// Read from any widget with `context.athar`. Every value is derived from the
/// active theme preset and brightness, so widgets never branch on either.
@immutable
class AtharPalette extends ThemeExtension<AtharPalette> {
  const AtharPalette({
    required this.brand,
    required this.gold,
    required this.goldText,
    required this.danger,
    required this.warning,
    required this.info,
    required this.sage,
    required this.beige,
    required this.card,
    required this.primaryDark,
    required this.textMuted,
    required this.success,
    required this.heroGradient,
  });

  /// The preset's deep identity colour.
  final Color brand;

  /// Soft gold — achievements, rewards, selected emphasis. Fills and icons.
  final Color gold;

  /// Gold that is readable as text on this brightness's surfaces.
  final Color goldText;

  final Color danger;

  /// Warm amber — missed / Qada states.
  final Color warning;

  final Color info;

  /// Sage — quiet decorative accent.
  final Color sage;

  /// Grouped section surface (a step off the background).
  final Color beige;

  /// Raised surface: cards, sheets, dialogs.
  final Color card;

  /// A deep shade of the action colour, dark enough for white text.
  final Color primaryDark;

  /// Secondary text.
  final Color textMuted;

  /// Completed / positive states.
  final Color success;

  /// The brand hero surface.
  final Gradient heroGradient;

  static AtharPalette get light =>
      AppTheme.paletteFor(AtharThemePreset.defaultPreset, Brightness.light);

  static AtharPalette get dark =>
      AppTheme.paletteFor(AtharThemePreset.defaultPreset, Brightness.dark);

  @override
  AtharPalette copyWith({
    Color? brand,
    Color? gold,
    Color? goldText,
    Color? danger,
    Color? warning,
    Color? info,
    Color? sage,
    Color? beige,
    Color? card,
    Color? primaryDark,
    Color? textMuted,
    Color? success,
    Gradient? heroGradient,
  }) {
    return AtharPalette(
      brand: brand ?? this.brand,
      gold: gold ?? this.gold,
      goldText: goldText ?? this.goldText,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
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
      brand: Color.lerp(brand, other.brand, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
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

/// Builds Athar's light and dark themes for any preset.
///
/// Each preset supplies a few hand-picked colours; everything else — surfaces,
/// text, outlines, states — is derived here by one set of rules, so all six
/// presets share the same hierarchy. Contrast targets: body and muted text at
/// least 4.5:1 on every surface, action colours at least 4.5:1 against their
/// label colour.
abstract final class AppTheme {
  static const _gold = Color(0xFFC8A95B);

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static ThemeData build(
    AtharThemePreset preset,
    Brightness brightness, {
    required bool arabic,
  }) {
    final scheme = colorScheme(preset, brightness);
    final palette = paletteFor(preset, brightness);
    final scaffold = brightness == Brightness.light ? preset.lightBackground : darkBackground(preset);
    final text = AtharTypography.textTheme(arabic: arabic, color: scheme.onSurface);

    const controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AtharRadius.md)),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.sm);
    const buttonMinimum = Size(64, 48);

    WidgetStateProperty<Color> selected(Color on, Color off) =>
        WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? on : off);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      textTheme: text,
      primaryTextTheme: text,
      extensions: [palette],
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtharRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinimum,
          padding: buttonPadding,
          shape: controlShape,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: buttonMinimum,
          padding: buttonPadding,
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          minimumSize: buttonMinimum,
          padding: buttonPadding,
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: AtharSpace.sm),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size.square(AtharSize.tap)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelMedium,
          shape: controlShape,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.card,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outline),
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        shape: const StadiumBorder(),
        checkmarkColor: scheme.onPrimaryContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: selected(scheme.onPrimary, scheme.outline),
        trackColor: selected(scheme.primary, scheme.surfaceContainerHighest),
        trackOutlineColor: selected(Colors.transparent, scheme.outline),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: selected(scheme.primary, Colors.transparent),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
      radioTheme: RadioThemeData(fillColor: selected(scheme.primary, scheme.onSurfaceVariant)),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.outlineVariant,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AtharSpace.md),
        shape: controlShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.md),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: scheme.primary),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtharRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtharRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtharRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtharRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtharRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        modalBackgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AtharRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AtharRadius.sheet)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AtharRadius.md)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        dividerColor: scheme.outlineVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AtharRadius.sm),
        ),
        textStyle: text.labelMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        textStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AtharRadius.md)),
      ),
    );
  }

  /// The dark-mode page colour: the preset's brand colour, deepened when it is
  /// too light for gold, state colours and muted text to read on its surfaces.
  static Color darkBackground(AtharThemePreset p) {
    var color = p.brand;
    for (var i = 0; i < 20 && color.computeLuminance() > 0.018; i++) {
      color = _mix(color, Colors.black, 0.08);
    }
    return color;
  }

  static ColorScheme colorScheme(AtharThemePreset p, Brightness brightness) {
    if (brightness == Brightness.light) {
      final text = _mix(p.brand, Colors.black, 0.60);
      final muted = _mix(text, p.lightBackground, 0.34);
      final card = _mix(Colors.white, p.lightBackground, 0.35);
      return ColorScheme(
        brightness: Brightness.light,
        primary: p.vivid,
        onPrimary: Colors.white,
        primaryContainer: _mix(p.lightBackground, p.vivid, 0.14),
        onPrimaryContainer: _mix(p.vivid, Colors.black, 0.35),
        secondary: _gold,
        onSecondary: const Color(0xFF231A05),
        secondaryContainer: _mix(p.lightBackground, _gold, 0.24),
        onSecondaryContainer: const Color(0xFF5C4513),
        tertiary: p.brand,
        onTertiary: Colors.white,
        error: const Color(0xFFA63D29),
        onError: Colors.white,
        surface: p.lightSurface,
        onSurface: text,
        onSurfaceVariant: muted,
        surfaceContainerLowest: card,
        surfaceContainerLow: _mix(p.lightBackground, p.lightSurface, 0.5),
        surfaceContainer: p.lightSurface,
        surfaceContainerHigh: _mix(p.lightSurface, text, 0.04),
        surfaceContainerHighest: _mix(p.lightSurface, text, 0.07),
        outline: p.lightOutline,
        outlineVariant: _mix(p.lightOutline, p.lightBackground, 0.45),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: p.brand,
        onInverseSurface: const Color(0xFFF1EEE6),
        inversePrimary: p.vividOnDark,
        surfaceTint: Colors.transparent,
      );
    }

    const text = Color(0xFFF1EEE6);
    final base = darkBackground(p);
    final muted = _mix(text, base, 0.30);
    final surface = _mix(base, Colors.white, 0.05);
    final card = _mix(base, Colors.white, 0.09);
    return ColorScheme(
      brightness: Brightness.dark,
      primary: p.vividOnDark,
      onPrimary: base,
      primaryContainer: _mix(base, p.vividOnDark, 0.24),
      onPrimaryContainer: _mix(p.vividOnDark, Colors.white, 0.45),
      secondary: _gold,
      onSecondary: const Color(0xFF231A05),
      secondaryContainer: _mix(base, _gold, 0.22),
      onSecondaryContainer: const Color(0xFFF3E3B8),
      tertiary: p.vividOnDark,
      onTertiary: base,
      error: const Color(0xFFEE8A73),
      onError: base,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceContainerLowest: _mix(base, Colors.black, 0.15),
      surfaceContainerLow: surface,
      surfaceContainer: card,
      surfaceContainerHigh: _mix(base, Colors.white, 0.12),
      surfaceContainerHighest: _mix(base, Colors.white, 0.15),
      outline: _mix(base, Colors.white, 0.17),
      outlineVariant: _mix(base, Colors.white, 0.11),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: text,
      onInverseSurface: base,
      inversePrimary: p.vivid,
      surfaceTint: Colors.transparent,
    );
  }

  static AtharPalette paletteFor(AtharThemePreset p, Brightness brightness) {
    final scheme = colorScheme(p, brightness);
    final primaryDark = _mix(p.vivid, p.brand, 0.55);

    if (brightness == Brightness.light) {
      return AtharPalette(
        brand: p.brand,
        gold: _gold,
        goldText: const Color(0xFF7A5E1E),
        danger: scheme.error,
        warning: const Color(0xFF87520F),
        info: const Color(0xFF2D6A9F),
        sage: const Color(0xFF6E9468),
        beige: p.lightSurface,
        card: scheme.surfaceContainerLowest,
        primaryDark: primaryDark,
        textMuted: scheme.onSurfaceVariant,
        success: const Color(0xFF1F6B50),
        heroGradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [_mix(p.brand, p.vivid, 0.55), p.brand],
        ),
      );
    }

    return AtharPalette(
      brand: p.brand,
      gold: _gold,
      goldText: _gold,
      danger: scheme.error,
      warning: const Color(0xFFE3A857),
      info: const Color(0xFF8DB9E6),
      sage: const Color(0xFFA8C3A0),
      beige: scheme.surface,
      card: scheme.surfaceContainer,
      primaryDark: primaryDark,
      textMuted: scheme.onSurfaceVariant,
      success: const Color(0xFF5CC49A),
      heroGradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [_mix(darkBackground(p), p.vivid, 0.45), _mix(darkBackground(p), Colors.white, 0.06)],
      ),
    );
  }
}
