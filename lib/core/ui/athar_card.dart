import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';

enum AtharCardTone {
  /// Sits in the page: a quiet tint, no border.
  surface,

  /// Lifted content: the card colour with a hairline border.
  raised,

  /// Border only, on the page colour.
  outlined,

  /// The brand hero surface. Content on it should be light.
  brand,
}

/// A content surface. Use sparingly — spacing and type group content well on
/// their own; a card is for something that is genuinely a unit.
class AtharCard extends StatelessWidget {
  const AtharCard({
    super.key,
    required this.child,
    this.onTap,
    this.tone = AtharCardTone.raised,
    this.padding = const EdgeInsets.all(AtharSpace.md),
    this.radius = AtharRadius.card,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final AtharCardTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final scheme = context.colors;
    final shape = BorderRadius.circular(radius);

    final (color, side) = switch (tone) {
      AtharCardTone.surface => (athar.beige, BorderSide.none),
      AtharCardTone.raised => (athar.card, BorderSide(color: scheme.outlineVariant)),
      AtharCardTone.outlined => (Colors.transparent, BorderSide(color: scheme.outline)),
      AtharCardTone.brand => (Colors.transparent, BorderSide.none),
    };

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: shape, child: content);
    }
    if (tone == AtharCardTone.brand) {
      content = Ink(
        decoration: BoxDecoration(gradient: athar.heroGradient, borderRadius: shape),
        child: content,
      );
    }

    Widget card = Material(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: shape, side: side),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (semanticLabel != null) {
      card = Semantics(label: semanticLabel, button: onTap != null, container: true, child: card);
    }
    return card;
  }
}
