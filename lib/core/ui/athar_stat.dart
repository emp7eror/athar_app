import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';
import 'athar_tone.dart';

/// One figure with its label — typography, not a card. Place several in a row
/// and let spacing group them.
class AtharStat extends StatelessWidget {
  const AtharStat({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tone = AtharTone.brand,
    this.center = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final AtharTone tone;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AtharSize.icon, color: tone.foreground(context)),
            const SizedBox(height: AtharSpace.xs),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: center ? Alignment.center : AlignmentDirectional.centerStart,
            child: Text(value, maxLines: 1, style: context.type.statValue),
          ),
          const SizedBox(height: AtharSpace.xxs / 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.type.caption,
          ),
        ],
      ),
    );
  }
}
