import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';

enum AtharButtonVariant {
  /// The one main action on a screen.
  primary,

  /// A calm alternative beside a primary action.
  secondary,

  /// A soft-filled action that shouldn't compete with a primary one.
  tonal,

  /// Text only, for low-emphasis actions.
  ghost,

  /// Irreversible or destructive actions.
  danger,
}

/// Athar's button. One shape and height everywhere; the variant says how much
/// the action matters.
class AtharButton extends StatelessWidget {
  const AtharButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AtharButtonVariant.primary,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;
  final AtharButtonVariant variant;

  /// Shows a spinner in place of the label and ignores taps.
  final bool loading;

  /// Fills the available width.
  final bool expand;

  /// A shorter button for inline actions.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final (background, foreground, border) = switch (variant) {
      AtharButtonVariant.primary => (scheme.primary, scheme.onPrimary, null),
      AtharButtonVariant.secondary => (Colors.transparent, scheme.onSurface, scheme.outline),
      AtharButtonVariant.tonal => (scheme.primaryContainer, scheme.onPrimaryContainer, null),
      AtharButtonVariant.ghost => (Colors.transparent, scheme.primary, null),
      AtharButtonVariant.danger => (scheme.error, scheme.onError, null),
    };
    final disabledLook = onPressed == null && !loading;

    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        disabledLook && background != Colors.transparent
            ? scheme.onSurface.withValues(alpha: 0.08)
            : background,
      ),
      foregroundColor: WidgetStatePropertyAll(
        disabledLook ? scheme.onSurface.withValues(alpha: 0.38) : foreground,
      ),
      overlayColor: WidgetStatePropertyAll(foreground.withValues(alpha: 0.1)),
      side: border == null
          ? null
          : WidgetStatePropertyAll(BorderSide(color: disabledLook ? scheme.outlineVariant : border)),
      minimumSize: WidgetStatePropertyAll(Size(compact ? 40 : 64, compact ? 40 : 52)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: compact ? AtharSpace.md : AtharSpace.lg),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AtharRadius.md))),
      ),
      textStyle: WidgetStatePropertyAll(context.text.labelLarge),
      elevation: const WidgetStatePropertyAll(0),
    );

    final child = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AtharSize.icon),
                const SizedBox(width: AtharSpace.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final button = Semantics(
      label: loading ? label : null,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: style,
        child: child,
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
