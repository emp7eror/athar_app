import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';

/// A selectable pill for choices: an optional icon and a label.
class AtharChoiceChip extends StatelessWidget {
  const AtharChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: AtharMotion.base,
        curve: AtharMotion.standard,
        decoration: ShapeDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? scheme.primary : scheme.outline),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onSelected,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: AtharSize.iconSm + 2, color: foreground),
                      const SizedBox(width: AtharSpace.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
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
