import 'package:flutter/painting.dart';

/// A curated colour theme. Each preset names only a handful of hand-picked
/// colours; the full light and dark colour systems are derived from them in
/// `AppTheme`, so every preset gets the same hierarchy and contrast rules.
///
/// Athar Green is the brand and the default. The others are personal choices
/// that keep Athar's calm, deep-toned character.
class AtharThemePreset {
  const AtharThemePreset({
    required this.id,
    required this.nameKey,
    required this.brand,
    required this.vivid,
    required this.vividOnDark,
    required this.lightBackground,
    required this.lightSurface,
    required this.lightOutline,
  });

  /// Stored on the device.
  final String id;

  /// Translation key of the preset's name.
  final String nameKey;

  /// The deep identity colour: the dark-mode background, hero surfaces, and
  /// the base of the light-mode text colour.
  final Color brand;

  /// The action colour in light mode: buttons, progress, selection. White text
  /// sits on it.
  final Color vivid;

  /// The action colour in dark mode, light enough to read on [brand].
  final Color vividOnDark;

  /// Light-mode page background — a warm, faintly tinted off-white.
  final Color lightBackground;

  /// Light-mode grouped surface, a step deeper than the background.
  final Color lightSurface;

  /// Light-mode outline.
  final Color lightOutline;

  static const atharGreen = AtharThemePreset(
    id: 'athar_green',
    nameKey: 'theme_athar_green',
    brand: Color(0xFF15201A),
    vivid: Color(0xFF0F6B4B),
    vividOnDark: Color(0xFF6FCB9F),
    lightBackground: Color(0xFFF7F5EF),
    lightSurface: Color(0xFFEEE8DC),
    lightOutline: Color(0xFFDDD4C3),
  );

  static const deepEmerald = AtharThemePreset(
    id: 'deep_emerald',
    nameKey: 'theme_deep_emerald',
    brand: Color(0xFF0E4D3A),
    vivid: Color(0xFF0B6A4F),
    vividOnDark: Color(0xFF8FE0BF),
    lightBackground: Color(0xFFF3F7F4),
    lightSurface: Color(0xFFE4EDE7),
    lightOutline: Color(0xFFCFDDD3),
  );

  static const midnightBlue = AtharThemePreset(
    id: 'midnight_blue',
    nameKey: 'theme_midnight_blue',
    brand: Color(0xFF141C2E),
    vivid: Color(0xFF2E5AA3),
    vividOnDark: Color(0xFF9DBBF2),
    lightBackground: Color(0xFFF4F6FA),
    lightSurface: Color(0xFFE6EAF2),
    lightOutline: Color(0xFFD2D9E6),
  );

  static const warmSand = AtharThemePreset(
    id: 'warm_sand',
    nameKey: 'theme_warm_sand',
    brand: Color(0xFF3A2F24),
    vivid: Color(0xFF855726),
    vividOnDark: Color(0xFFDDB887),
    lightBackground: Color(0xFFFAF6EE),
    lightSurface: Color(0xFFF0E6D5),
    lightOutline: Color(0xFFE0D2BC),
  );

  static const burgundy = AtharThemePreset(
    id: 'burgundy',
    nameKey: 'theme_burgundy',
    brand: Color(0xFF2E1519),
    vivid: Color(0xFF8A2D3A),
    vividOnDark: Color(0xFFEE9EA8),
    lightBackground: Color(0xFFFAF5F5),
    lightSurface: Color(0xFFF1E5E6),
    lightOutline: Color(0xFFE2CFD1),
  );

  static const slate = AtharThemePreset(
    id: 'slate',
    nameKey: 'theme_slate',
    brand: Color(0xFF1C2127),
    vivid: Color(0xFF3D5366),
    vividOnDark: Color(0xFFAFC3D2),
    lightBackground: Color(0xFFF5F6F7),
    lightSurface: Color(0xFFE8EBEE),
    lightOutline: Color(0xFFD5DAE0),
  );

  static const defaultPreset = atharGreen;

  static const all = [atharGreen, deepEmerald, midnightBlue, warmSand, burgundy, slate];

  static AtharThemePreset byId(String? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return defaultPreset;
  }
}
