import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';

/// A section title, optionally with a short subtitle and one action.
class AtharSectionHeader extends StatelessWidget {
  const AtharSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsetsDirectional.only(bottom: AtharSpace.sm),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.type.sectionTitle),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AtharSpace.xxs / 2),
                  Text(subtitle!, style: context.type.caption),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
