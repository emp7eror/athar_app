import 'package:flutter/material.dart';

/// The reader's text and interface size.
enum AtharTextSize {
  small(0.9, 'text_size_small'),
  standard(1.0, 'text_size_default'),
  large(1.15, 'text_size_large'),
  extraLarge(1.3, 'text_size_xl');

  const AtharTextSize(this.factor, this.labelKey);

  final double factor;
  final String labelKey;

  static AtharTextSize byName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return standard;
  }
}

/// The chosen interface size, for components that size more than text —
/// icons, tiles, touch targets.
class AtharScale extends InheritedWidget {
  const AtharScale({super.key, required this.factor, required super.child});

  final double factor;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AtharScale>()?.factor ?? 1.0;

  @override
  bool updateShouldNotify(AtharScale oldWidget) => oldWidget.factor != factor;
}

/// Applies the chosen size on top of the device's own text size.
///
/// The device setting is honoured but bounded, so the two together stay
/// within what layouts are built for. Icons grow a little with the interface,
/// less than text does.
class AtharScaleScope extends StatelessWidget {
  const AtharScaleScope({super.key, required this.size, required this.child});

  final AtharTextSize size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final device = (media.textScaler.scale(14) / 14).clamp(0.85, 1.5);
    final combined = (device * size.factor).clamp(0.8, 1.9);
    final iconFactor = size.factor.clamp(0.9, 1.2);

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(combined)),
      child: AtharScale(
        factor: size.factor,
        child: IconTheme.merge(
          data: IconThemeData(size: 24 * iconFactor),
          child: child,
        ),
      ),
    );
  }
}
