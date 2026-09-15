import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The meaning a component's colour carries. Components take a tone, never a
/// raw colour, so every theme resolves it the same way.
enum AtharTone { neutral, brand, gold, success, warning, danger, info }

extension AtharToneColors on AtharTone {
  /// For text and icons.
  Color foreground(BuildContext context) => switch (this) {
        AtharTone.neutral => context.colors.onSurfaceVariant,
        AtharTone.brand => context.colors.primary,
        AtharTone.gold => context.athar.goldText,
        AtharTone.success => context.athar.success,
        AtharTone.warning => context.athar.warning,
        AtharTone.danger => context.colors.error,
        AtharTone.info => context.athar.info,
      };

  /// A quiet tint behind [foreground].
  Color background(BuildContext context) => switch (this) {
        AtharTone.gold => context.athar.gold.withValues(alpha: 0.16),
        _ => foreground(context).withValues(alpha: 0.12),
      };
}
