import 'package:flutter/material.dart';

/// A tally that rolls to its new value instead of snapping to it.
///
/// Only the digits that actually changed animate, so counting from 9 to 10
/// doesn't shuffle the whole number — the effect stays calm at any tally.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 320),
  });

  final int value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final digits = value.toString().split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (var i = 0; i < digits.length; i++)
          _Digit(
            // Keyed from the right so place value stays stable as the number
            // grows; otherwise every digit re-animates when a column is added.
            key: ValueKey('digit-${digits.length - i}'),
            digit: digits[i],
            style: style,
            duration: duration,
          ),
      ],
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit({
    super.key,
    required this.digit,
    required this.style,
    required this.duration,
  });

  final String digit;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final entering = child.key == ValueKey(digit);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              // New digits rise into place; the old one continues upward out.
              begin: Offset(0, entering ? 0.55 : -0.55),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [...previous, ?current],
      ),
      child: Text(digit, key: ValueKey(digit), style: style),
    );
  }
}
