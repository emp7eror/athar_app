import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';
import 'athar_tone.dart';

/// A small status pill: an optional icon and a short label, in a tone.
class AtharBadge extends StatelessWidget {
  const AtharBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AtharTone.neutral,
  });

  final String label;
  final IconData? icon;
  final AtharTone tone;

  @override
  Widget build(BuildContext context) {
    final foreground = tone.foreground(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.xs + 2, vertical: AtharSpace.xxs),
      decoration: BoxDecoration(
        color: tone.background(context),
        borderRadius: BorderRadius.circular(AtharRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AtharSize.iconSm, color: foreground),
            const SizedBox(width: AtharSpace.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
