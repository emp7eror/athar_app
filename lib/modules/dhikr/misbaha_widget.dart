import 'dart:math' as math;

import 'package:athar/core/ui/athar_ui.dart';
import 'package:flutter/material.dart';

class MisbahaMotion {
  const MisbahaMotion({
    this.duration = const Duration(milliseconds: 500),
  });

  final Duration duration;
}

class MisbahaStrand extends StatefulWidget {
  const MisbahaStrand({
    super.key,
    required this.count,
    required this.onTap,
    required this.enabled,
    this.motion = const MisbahaMotion(),
  });

  final int count;
  final bool Function() onTap;
  final bool enabled;
  final MisbahaMotion motion;

  static const beadCount = 13;

  @override
  State<MisbahaStrand> createState() => _MisbahaStrandState();
}

class _MisbahaStrandState extends State<MisbahaStrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController =
  AnimationController(
    vsync: this,
    duration: widget.motion.duration,
  );

  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
  }

  @override
  void didUpdateWidget(MisbahaStrand oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.count != _previousCount) {
      _previousCount = widget.count;
      _animateBead();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;

    final accepted = widget.onTap();

    if (!accepted) return;

    _animateBead();
  }

  void _animateBead() {
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final beadLight = colors.primary;

    final beadMid = Color.alphaBlend(
      colors.primary.withValues(alpha: 0.55),
      colors.surface,
    );

    final beadDark = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.45),
      colors.primary,
    );

    return GestureDetector(
      onTap: _handleTap,
      onHorizontalDragEnd: _handleSwipe,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 220),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            return CustomPaint(
              painter: _MisbahaPainter(
                progress: Curves.easeOutCubic.transform(
                  _animationController.value,
                ),
                beadCount: MisbahaStrand.beadCount,
                beadLight: beadLight,
                beadMid: beadMid,
                beadDark: beadDark,
                gold: context.athar.gold,
                goldBright: colors.onPrimary,
                cord: colors.onSurfaceVariant,
                shadow: colors.shadow,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  void _handleSwipe(DragEndDetails details) {
    print('ssss');
    _handleTap();
  }
}

class _MisbahaPainter extends CustomPainter {
  _MisbahaPainter({
    required this.progress,
    required this.beadCount,
    required this.beadLight,
    required this.beadMid,
    required this.beadDark,
    required this.gold,
    required this.goldBright,
    required this.cord,
    required this.shadow,
  });

  final double progress;
  final int beadCount;

  final Color beadLight;
  final Color beadMid;
  final Color beadDark;
  final Color gold;
  final Color goldBright;
  final Color cord;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final beadRadius = math.min(
      size.height * 0.15,
      25.0,
    );

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final points = _buildUPath(
      center: center,
      width: size.width * 0.82,
      height: size.height * 0.76,
    );

    if (points.length < 2) return;

    final lengths = <double>[0];
    var totalLength = 0.0;

    for (var i = 1; i < points.length; i++) {
      totalLength +=
          (points[i] - points[i - 1]).distance;

      lengths.add(totalLength);
    }

    _paintCord(canvas, points);

    final spacing =
        totalLength / (beadCount - 1);

    /*
     * Move the entire strand by one bead position.
     *
     * We deliberately clamp the positions instead
     * of wrapping them, preventing an extra bead
     * from appearing above the right endpoint.
     */
    final movement = spacing * progress;

    for (var i = 0; i < beadCount; i++) {
      final distance = (i * spacing + movement)
          .clamp(0.0, totalLength);

      final centre = _pointAtDistance(
        points,
        lengths,
        distance,
      );

      _paintBead(
        canvas,
        centre: centre,
        radius: beadRadius,
      );
    }
  }

  List<Offset> _buildUPath({
    required Offset center,
    required double width,
    required double height,
  }) {
    final points = <Offset>[];

    const samples = 300;

    for (var i = 0; i <= samples; i++) {
      final t = i / samples;

      final x =
          center.dx -
              width / 2 +
              width * t;

      /*
       * Smooth stretched U.
       *
       * Ends are high.
       * Bottom is broad and rounded.
       */
      final normalized =
          (t - 0.5) * math.pi;

      final curve =
      math.cos(normalized).abs();

      final y =
          center.dy +
              height * 0.46 -
              height * 0.86 * curve;

      points.add(
        Offset(x, y),
      );
    }

    return points;
  }

  Offset _pointAtDistance(
      List<Offset> points,
      List<double> lengths,
      double distance,
      ) {
    if (distance <= 0) {
      return points.first;
    }

    if (distance >= lengths.last) {
      return points.last;
    }

    for (var i = 1; i < points.length; i++) {
      if (lengths[i] >= distance) {
        final segment =
            lengths[i] - lengths[i - 1];

        if (segment <= 0) {
          return points[i];
        }

        final t =
            (distance - lengths[i - 1]) /
                segment;

        return Offset.lerp(
          points[i - 1],
          points[i],
          t,
        )!;
      }
    }

    return points.last;
  }

  void _paintCord(
      Canvas canvas,
      List<Offset> points,
      ) {
    final path = Path()
      ..moveTo(
        points.first.dx,
        points.first.dy,
      );

    for (var i = 1; i < points.length; i++) {
      path.lineTo(
        points[i].dx,
        points[i].dy,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = cord.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintBead(
      Canvas canvas, {
        required Offset centre,
        required double radius,
      }) {
    final rect = Rect.fromCircle(
      center: centre,
      radius: radius,
    );

    // Shadow.
    canvas.drawCircle(
      centre.translate(
        0,
        radius * 0.20,
      ),
      radius * 0.98,
      Paint()
        ..color = shadow.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          7,
        ),
    );

    // Main bead.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(
            -0.45,
            -0.5,
          ),
          radius: 1.05,
          colors: [
            beadLight,
            beadMid,
            beadDark,
          ],
          stops: const [
            0.0,
            0.55,
            1.0,
          ],
        ).createShader(rect),
    );

    // Gold rim.
    canvas.drawCircle(
      centre,
      radius - 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goldBright.withValues(alpha: 0.72),
            gold.withValues(alpha: 0.20),
          ],
        ).createShader(rect),
    );

    // Highlight.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre.translate(
          -radius * 0.34,
          -radius * 0.38,
        ),
        width: radius * 0.62,
        height: radius * 0.44,
      ),
      Paint()
        ..color = Colors.white.withValues(
          alpha: 0.23,
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          radius * 0.20,
        ),
    );

    // Reflection.
    canvas.drawArc(
      Rect.fromCircle(
        center: centre,
        radius: radius * 0.82,
      ),
      math.pi * 0.15,
      math.pi * 0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12
        ..color = beadLight.withValues(
          alpha: 0.30,
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          radius * 0.18,
        ),
    );
  }

  @override
  bool shouldRepaint(
      _MisbahaPainter oldDelegate,
      ) {
    return oldDelegate.progress != progress ||
        oldDelegate.beadCount != beadCount ||
        oldDelegate.beadLight != beadLight ||
        oldDelegate.beadMid != beadMid ||
        oldDelegate.beadDark != beadDark ||
        oldDelegate.gold != gold ||
        oldDelegate.goldBright != goldBright ||
        oldDelegate.cord != cord ||
        oldDelegate.shadow != shadow;
  }
}