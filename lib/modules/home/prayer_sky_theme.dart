import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sky mood for the next-prayer hero card — one per prayer, so the card reads
/// like the time of day it's counting down to (dawn, midday, afternoon,
/// sunset, night).
class PrayerSkyTheme {
  const PrayerSkyTheme({
    required this.colors,
    required this.accent,
    required this.watermark,
    required this.glow,
    this.stars = 0,
  });

  /// Background gradient, top-start → bottom-end.
  final List<Color> colors;

  /// Countdown + small icons. Chosen per sky so it stays legible.
  final Color accent;

  /// Large faded icon in the corner (sun / moon / twilight).
  final IconData watermark;

  /// Soft light source behind the watermark (sun glow, moonlight).
  final Color glow;

  /// How many faint stars to scatter (0 for daytime skies).
  final int stars;

  static const fajr = PrayerSkyTheme(
    colors: [Color(0xFF1B2447), Color(0xFF4A4E7E), Color(0xFFB9838B)],
    accent: Color(0xFFF6D9B8),
    watermark: Icons.wb_twilight_rounded,
    glow: Color(0xFFF3B79B),
    stars: 14,
  );

  static const dhuhr = PrayerSkyTheme(
    colors: [Color(0xFF14507E), Color(0xFF2C7DB3)],
    accent: Color(0xFFFFE3A3),
    watermark: Icons.wb_sunny_rounded,
    glow: Color(0xFFFFE9A8),
  );

  static const asr = PrayerSkyTheme(
    colors: [Color(0xFF6B4220), Color(0xFFB0752F)],
    accent: Color(0xFFFFE7B8),
    watermark: Icons.wb_sunny_outlined,
    glow: Color(0xFFFFC56B),
  );

  static const maghrib = PrayerSkyTheme(
    colors: [Color(0xFF3A1D46), Color(0xFF9E3F44), Color(0xFFE2844F)],
    accent: Color(0xFFFFD9A0),
    watermark: Icons.wb_twilight_rounded,
    glow: Color(0xFFFF9F5A),
    stars: 5,
  );

  static const isha = PrayerSkyTheme(
    colors: [Color(0xFF0A1024), Color(0xFF1C2A52)],
    accent: Color(0xFFC8A95B),
    watermark: Icons.nightlight_round,
    glow: Color(0xFFBFD0FF),
    stars: 26,
  );

  /// Brand ink — used before the next prayer is known.
  static const fallback = PrayerSkyTheme(
    colors: [Color(0xFF243329), Color(0xFF15201A)],
    accent: Color(0xFFC8A95B),
    watermark: Icons.mosque_outlined,
    glow: Color(0xFFC8A95B),
  );

  static PrayerSkyTheme of(String prayerKey) => switch (prayerKey) {
        'fajr' => fajr,
        'dhuhr' => dhuhr,
        'asr' => asr,
        'maghrib' => maghrib,
        'isha' => isha,
        _ => fallback,
      };
}

/// Faint twinkle of stars; positions are seeded so they never jump between
/// rebuilds.
class SkyStarsPainter extends CustomPainter {
  const SkyStarsPainter({required this.count, this.color = Colors.white});

  final int count;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0) return;
    final rnd = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      // Keep stars in the upper two-thirds, like a real sky.
      final dy = rnd.nextDouble() * size.height * 0.66;
      final r = 0.6 + rnd.nextDouble() * 1.2;
      paint.color = color.withValues(alpha: 0.25 + rnd.nextDouble() * 0.45);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SkyStarsPainter old) =>
      old.count != count || old.color != color;
}
