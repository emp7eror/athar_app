import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';

/// A rounded progress bar with its value exposed to screen readers.
class AtharProgressBar extends StatelessWidget {
  const AtharProgressBar({
    super.key,
    required this.value,
    this.color,
    this.trackColor,
    this.height = 8,
    this.semanticsLabel,
    this.semanticsValue,
  });

  /// 0..1.
  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue ?? '${(value.clamp(0, 1) * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AtharRadius.pill),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: AtharMotion.slow,
          curve: AtharMotion.standard,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: height,
            color: color ?? context.colors.primary,
            backgroundColor: trackColor ?? context.colors.outlineVariant,
          ),
        ),
      ),
    );
  }
}

/// A progress ring, optionally with something at its centre.
class AtharProgressRing extends StatelessWidget {
  const AtharProgressRing({
    super.key,
    required this.value,
    this.size = 40,
    this.strokeWidth = 4,
    this.color,
    this.trackColor,
    this.child,
    this.semanticsLabel,
  });

  /// 0..1.
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? child;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: value.clamp(0.0, 1.0)),
                duration: AtharMotion.slow,
                curve: AtharMotion.standard,
                builder: (context, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: color ?? context.colors.primary,
                  backgroundColor: trackColor ?? context.colors.outlineVariant,
                ),
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}
