import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';

class AtharSegment<T> {
  const AtharSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A compact set of mutually exclusive options on one track — for modes and
/// filters. The selected option lifts onto the card colour.
class AtharSegmented<T> extends StatelessWidget {
  const AtharSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<AtharSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final scheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(AtharSpace.xxs),
      decoration: BoxDecoration(
        color: athar.beige,
        borderRadius: BorderRadius.circular(AtharRadius.md + AtharSpace.xxs),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: _Segment(
                segment: s,
                selected: s.value == selected,
                onTap: () => onChanged(s.value),
                card: athar.card,
                outline: scheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.onTap,
    required this.card,
    required this.outline,
  });

  final AtharSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;
  final Color card;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final foreground = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final radius = BorderRadius.circular(AtharRadius.md);

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: AtharMotion.base,
        curve: AtharMotion.standard,
        decoration: BoxDecoration(
          color: selected ? card : Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: selected ? outline : Colors.transparent),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AtharSpace.xxs, vertical: AtharSpace.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (segment.icon != null) ...[
                      Icon(segment.icon, size: AtharSize.iconSm + 2, color: selected ? scheme.primary : foreground),
                      const SizedBox(width: AtharSpace.xxs + 2),
                    ],
                    Flexible(
                      child: Text(
                        segment.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelMedium?.copyWith(color: foreground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
