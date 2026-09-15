import 'package:flutter/material.dart';

import '../design/athar_scale.dart';
import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';

enum AtharIconButtonVariant { plain, tonal, outlined, filled }

/// A round icon action with a 48px touch target and a required tooltip, which
/// is also its screen-reader label.
class AtharIconButton extends StatelessWidget {
  const AtharIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AtharIconButtonVariant.plain,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AtharIconButtonVariant variant;

  /// Overrides the icon colour for the plain, tonal and outlined variants.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final size = 22 * AtharScale.of(context).clamp(1.0, 1.2);
    final (background, foreground, side) = switch (variant) {
      AtharIconButtonVariant.plain => (Colors.transparent, color ?? scheme.onSurface, null),
      AtharIconButtonVariant.tonal => (scheme.onSurface.withValues(alpha: 0.06), color ?? scheme.onSurface, null),
      AtharIconButtonVariant.outlined => (Colors.transparent, color ?? scheme.onSurface, BorderSide(color: scheme.outline)),
      AtharIconButtonVariant.filled => (scheme.primary, scheme.onPrimary, null),
    };

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: size,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        side: side,
        minimumSize: const Size.square(AtharSize.tap),
        shape: const CircleBorder(),
      ),
    );
  }
}
