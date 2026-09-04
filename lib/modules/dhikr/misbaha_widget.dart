import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A hand-painted misbaha strand.
///
/// The beads are drawn rather than modelled: each one is a radial gradient with
/// a specular highlight, a darkened rim and a contact shadow, which reads as a
/// polished sphere without pulling in a 3D engine. The strand hangs as a shallow
/// arc across the bottom of the screen with the large separator bead at its
/// lowest point, so the whole thing sits under the thumb in one-handed use.
class MisbahaStrand extends StatefulWidget {
  const MisbahaStrand({
    super.key,
    required this.count,
    required this.onTap,
    required this.enabled,
  });

  /// Current tally — decides which bead is lit.
  final int count;

  /// Returns true when the tap was counted; false while the counter is paused.
  final bool Function() onTap;

  /// False during the rapid-tap cooldown; dims the strand.
  final bool enabled;

  /// Beads either side of the separator.
  static const beadsPerSide = 6;

  @override
  State<MisbahaStrand> createState() => _MisbahaStrandState();
}

class _MisbahaStrandState extends State<MisbahaStrand> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.onTap()) return;
    _pulse.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTap(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 220),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => CustomPaint(
            painter: _MisbahaPainter(
              count: widget.count,
              pulse: _pulse.value,
              beadsPerSide: MisbahaStrand.beadsPerSide,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _MisbahaPainter extends CustomPainter {
  _MisbahaPainter({
    required this.count,
    required this.pulse,
    required this.beadsPerSide,
  });

  final int count;
  final double pulse;
  final int beadsPerSide;

  // Dark emerald body, gold accents.
  static const _beadLight = Color(0xFF1E6B4F);
  static const _beadMid = Color(0xFF0E4433);
  static const _beadDark = Color(0xFF04170F);
  static const _gold = Color(0xFFC8A95B);
  static const _goldBright = Color(0xFFEBD9A3);
  static const _cord = Color(0xFF2A2018);

  @override
  void paint(Canvas canvas, Size size) {
    final beadCount = beadsPerSide * 2;
    // Which bead is lit: walks the strand and wraps, so the strand always shows
    // motion no matter how high the tally goes.
    final activeIndex = beadCount == 0 ? 0 : count % beadCount;

    final beadRadius = math.min(size.width / 16, 26.0);
    final separatorRadius = beadRadius * 1.45;

    // Arc geometry: a wide, shallow circle whose lowest point is the separator.
    final arcRadius = size.width * 0.78;
    final centre = Offset(size.width / 2, size.height - separatorRadius * 1.9 - arcRadius);
    final spread = 0.62; // radians either side of straight down

    Offset positionAt(double t) {
      // t: -1 (far left) .. 0 (bottom) .. 1 (far right)
      final angle = spread * t;
      return centre + Offset(math.sin(angle) * arcRadius, math.cos(angle) * arcRadius);
    }

    _paintCord(canvas, positionAt);

    // Beads run outward from the separator on both sides.
    for (var i = 0; i < beadCount; i++) {
      final side = i < beadsPerSide ? -1 : 1;
      final rank = i < beadsPerSide ? beadsPerSide - i : i - beadsPerSide + 1;
      final t = side * (rank / (beadsPerSide + 0.6));

      final lit = i == activeIndex;
      // Only the lit bead reacts, and only while the pulse is running.
      final scale = lit ? 1 + 0.14 * _pulseCurve(pulse) : 1.0;

      _paintBead(
        canvas,
        centre: positionAt(t),
        radius: beadRadius * scale,
        glow: lit ? (1 - pulse).clamp(0.0, 1.0) : 0,
      );
    }

    // The imame sits at the lowest point of the arc.
    _paintBead(
      canvas,
      centre: positionAt(0),
      radius: separatorRadius,
      glow: 0,
      isSeparator: true,
    );
  }

  /// Fast rise, gentle settle — the bead never lingers enlarged.
  double _pulseCurve(double t) {
    if (t <= 0 || t >= 1) return 0;
    return math.sin(t * math.pi) * (1 - t * 0.35);
  }

  void _paintCord(Canvas canvas, Offset Function(double) positionAt) {
    final path = Path()..moveTo(positionAt(-1.12).dx, positionAt(-1.12).dy);
    for (var t = -1.12; t <= 1.12; t += 0.04) {
      final p = positionAt(t);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = _cord
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintBead(
    Canvas canvas, {
    required Offset centre,
    required double radius,
    required double glow,
    bool isSeparator = false,
  }) {
    // Contact shadow — grounds the bead against the background.
    canvas.drawCircle(
      centre.translate(0, radius * 0.22),
      radius * 0.96,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Golden halo on the bead just counted.
    if (glow > 0) {
      canvas.drawCircle(
        centre,
        radius * (1.22 + 0.5 * (1 - glow)),
        Paint()
          ..color = _gold.withValues(alpha: 0.34 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.7),
      );
    }

    final rect = Rect.fromCircle(center: centre, radius: radius);

    // Body: light comes from the upper left, so the gradient's focal point sits
    // there and falls away to near-black at the lower right.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.5),
          radius: 1.05,
          colors: const [_beadLight, _beadMid, _beadDark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Gold rim, brightest where the light hits.
    canvas.drawCircle(
      centre,
      radius - 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSeparator ? 1.8 : 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _goldBright.withValues(alpha: glow > 0 ? 0.95 : 0.62),
            _gold.withValues(alpha: 0.18),
          ],
        ).createShader(rect),
    );

    // Specular highlight.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre.translate(-radius * 0.34, -radius * 0.38),
        width: radius * 0.62,
        height: radius * 0.44,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.22),
    );

    // Bounce light along the lower edge keeps the sphere from reading as flat.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius * 0.82),
      math.pi * 0.15,
      math.pi * 0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12
        ..color = _beadLight.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
    );

    // A gold band marks the separator without changing its silhouette.
    if (isSeparator) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius * 0.55),
        -math.pi * 0.85,
        math.pi * 0.7,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.1
          ..color = _gold.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_MisbahaPainter old) =>
      old.count != count || old.pulse != pulse || old.beadsPerSide != beadsPerSide;
}
