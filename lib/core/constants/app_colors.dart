import 'package:flutter/material.dart';

/// Athar (أثر) brand palette — single source of truth for raw color values.
///
/// These map 1:1 to the visual-identity guide. Prefer reading colors from the
/// active [Theme] (ColorScheme / AtharPalette extension) in widgets; this class
/// exists for the [ThemeData] definition and a few legacy call sites.
class AppColors {
  // ── Core identity ────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F6B4B); // Deep Emerald Green
  static const Color primaryDark = Color(0xFF0A4D36); // gradient shade
  static const Color secondary = Color(0xFFC8A95B); // Soft Gold
  static const Color sage = Color(0xFFA8C3A0); // Sage Green (status/success)
  static const Color bg = Color(0xFFFAF9F5); // Warm White (scaffold)
  static const Color surface = Color(0xFFF1E8D8); // Light Beige (cards)
  static const Color textDark = Color(0xFF1E1E1E); // Charcoal
  static const Color textMuted = Color(0xFF6B6B6B);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF2F8F6B); // completed states
  static const Color danger = Color(0xFFC0563B);

  // ── Legacy aliases (kept so existing views stay on-brand) ─────────
  static const Color accent = secondary;
  static const Color card = surface;
}
