import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How the pull travels down the string. Kept separate from the widget so the
/// feel can be tuned — or a second strand given a different character — without
/// touching the drawing code.
class MisbahaMotion {
  const MisbahaMotion({
    this.amplitude = 0.062,
    this.falloff = 0.62,
    this.trailingFactor = 0.5,
    this.reach = 4,
    this.stagger = const Duration(milliseconds: 52),
    this.settle = const Duration(milliseconds: 520),
    this.damping = 2.6,
    this.springiness = 1.3,
  });

  /// How far the struck bead slides, in arc-parameter units.
  final double amplitude;

  /// Share of the movement each further bead receives: 0.62 gives the next
  /// bead 62%, the one after 38%, then 24% — the tension thinning out as it
  /// travels, the way it does on a real string.
  final double falloff;

  /// Beads behind the struck one are dragged less than those ahead of it.
  final double trailingFactor;

  /// Beads further than this stay put; their share would be invisible anyway.
  final int reach;

  /// Delay added per bead of distance, which is what makes it a ripple rather
  /// than everything twitching at once.
  final Duration stagger;

  /// How long one bead takes to swing out and settle back.
  final Duration settle;

  /// Higher settles sooner. Tuned so the return reads as weight, not bounce.
  final double damping;

  /// Slightly over 1 leaves a small counter-swing — the spring in the string.
  final double springiness;

  Duration get total => settle + stagger * reach;

  double get _staggerFraction => stagger.inMicroseconds / total.inMicroseconds;

  double get _settleFraction => settle.inMicroseconds / total.inMicroseconds;

  /// Displacement of a bead [distance] beads from the struck one, at [phase]
  /// (0..1) through the impulse. Positive moves it along the string.
  double displacement(int distance, double phase, {required bool trailing}) {
    final steps = distance.abs();
    if (steps > reach) return 0;

    var share = amplitude * math.pow(falloff, steps).toDouble();
    if (trailing) share *= trailingFactor;

    final local = (phase - steps * _staggerFraction) / _settleFraction;
    return share * _spring(local);
  }

  /// A damped swing: out, back, and a much smaller counter-swing. Normalised so
  /// the peak is exactly 1 whatever [damping] and [springiness] are, which is
  /// what keeps [falloff] honest — each bead really does move the share it says.
  double _spring(double x) {
    if (x <= 0 || x >= 1) return 0;

    final a = math.pi * springiness;

    // The damping drags the maximum earlier than the sine's own peak, so it has
    // to be solved for: d/dx[sin(ax)·e^(-bx)] = 0 when tan(ax) = a/b.
    final peakAt = math.atan(a / damping) / a;
    final norm = math.sin(a * peakAt) * math.exp(-damping * peakAt);

    return math.sin(a * x) * math.exp(-damping * x) / norm;
  }
}

/// A hand-painted misbaha strand.
///
/// The beads are drawn rather than modelled: each is a radial gradient with a
/// specular highlight, a darkened rim and a contact shadow, which reads as a
/// polished sphere without pulling in a 3D engine. The strand hangs as a shallow
/// arc across the bottom of the screen with the large separator bead at its
/// lowest point, so the whole thing sits under the thumb in one-handed use.
///
/// A tap slides the struck bead along the arc and the pull travels outward from
/// it, each neighbour picking the movement up a moment later and a little more
/// weakly. Everything is driven by one controller and painted in one pass, so
/// the cascade costs no more than a single bead would.
class MisbahaStrand extends StatefulWidget {
  const MisbahaStrand({
    super.key,
    required this.count,
    required this.onTap,
    required this.enabled,
    this.strike = 0,
    this.motion = const MisbahaMotion(),
  });

  /// Bumped from outside — e.g. a counted phone shake — to play the same pull
  /// a tap does.
  final int strike;

  /// Current tally — decides which bead is struck.
  final int count;

  /// Returns true when the tap was counted; false while the counter is paused.
  final bool Function() onTap;

  /// False during the rapid-tap cooldown; dims the strand.
  final bool enabled;

  final MisbahaMotion motion;

  /// Beads either side of the separator.
  static const beadsPerSide = 6;

  @override
  State<MisbahaStrand> createState() => _MisbahaStrandState();
}

class _MisbahaStrandState extends State<MisbahaStrand> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: widget.motion.total,
  );

  /// The bead the pull started from.
  int _struck = 0;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MisbahaStrand oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A shake was counted: [count] already includes it, so the pushed bead is
    // the one before.
    if (widget.strike != oldWidget.strike) _pull(widget.count - 1);
  }

  void _handleTap() {
    if (!widget.onTap()) return;

    // The bead that has just been counted is the one the thumb pushed.
    _pull(widget.count);
  }

  void _pull(int countedAt) {
    _struck = _activeIndex(countedAt);
    _pulse.forward(from: 0);
  }

  int _activeIndex(int count) {
    const beads = MisbahaStrand.beadsPerSide * 2;
    return count % beads;
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
              activeIndex: _activeIndex(widget.count),
              struckIndex: _struck,
              phase: _pulse.value,
              motion: widget.motion,
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
    required this.activeIndex,
    required this.struckIndex,
    required this.phase,
    required this.motion,
    required this.beadsPerSide,
  });

  final int activeIndex;
  final int struckIndex;
  final double phase;
  final MisbahaMotion motion;
  final int beadsPerSide;

  // Dark emerald body, gold accents.
  static const _beadLight = Color(0xFF1E6B4F);
  static const _beadMid = Color(0xFF0E4433);
  static const _beadDark = Color(0xFF04170F);
  static const _gold = Color(0xFFC8A95B);
  static const _goldBright = Color(0xFFEBD9A3);
  static const _cord = Color(0xFF2A2018);

  /// Half-width of the gap kept clear for the separator.
  static const _gap = 0.20;

  /// Spacing between neighbouring beads, in arc-parameter units.
  static const _spacing = 0.145;

  @override
  void paint(Canvas canvas, Size size) {
    final beadCount = beadsPerSide * 2;

    final beadRadius = math.min(size.width / 16, 26.0);
    final separatorRadius = beadRadius * 1.45;

    // Arc geometry: a wide, shallow circle whose lowest point is the separator.
    final arcRadius = size.width * 0.78;
    final centre = Offset(size.width / 2, size.height - separatorRadius * 1.9 - arcRadius);
    const spread = 0.62; // radians either side of straight down

    Offset positionAt(double t) {
      final angle = spread * t;
      return centre + Offset(math.sin(angle) * arcRadius, math.cos(angle) * arcRadius);
    }

    _paintCord(canvas, positionAt);

    for (var i = 0; i < beadCount; i++) {
      // Beads run outward from the separator on both sides, leaving it a gap.
      final side = i < beadsPerSide ? -1 : 1;
      final rank = i < beadsPerSide ? beadsPerSide - 1 - i : i - beadsPerSide;
      final base = side * (_gap + rank * _spacing);

      // The pull propagates along the string, so a bead's share depends on how
      // many beads separate it from the one that was struck.
      final offset = i - struckIndex;
      final slide = motion.displacement(offset, phase, trailing: offset < 0);

      // Movement follows the curve of the string, not a straight line: the
      // displacement is applied to the arc parameter, then resolved to a point.
      final position = positionAt(base + slide * side.toDouble());

      final lit = i == activeIndex;
      // A touch of scale supports the movement without standing in for it.
      final struck = i == struckIndex ? _swell(phase) : 0.0;

      _paintBead(
        canvas,
        centre: position,
        radius: beadRadius * (1 + 0.05 * struck),
        glow: lit ? (1 - phase).clamp(0.0, 1.0) : 0,
      );
    }

    // The imame sits at the lowest point of the arc and never moves — it is
    // the anchor the rest of the strand is pulled against.
    _paintBead(
      canvas,
      centre: positionAt(0),
      radius: separatorRadius,
      glow: 0,
      isSeparator: true,
    );
  }

  /// Brief swell on the struck bead, gone well before the slide settles.
  double _swell(double x) {
    if (x <= 0 || x >= 0.5) return 0;
    return math.sin(x * 2 * math.pi);
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
      old.phase != phase ||
      old.activeIndex != activeIndex ||
      old.struckIndex != struckIndex ||
      old.beadsPerSide != beadsPerSide;
}
