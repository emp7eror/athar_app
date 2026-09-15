import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';
import '../theme/app_theme.dart';

/// The title row at the top of a tab screen (which has no app bar): the
/// screen's name, an optional line under it, and its actions.
class AtharPageHeader extends StatelessWidget {
  const AtharPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(header: true, child: Text(title, style: context.text.headlineMedium)),
              if (subtitle != null) ...[
                const SizedBox(height: AtharSpace.xxs / 2),
                Text(subtitle!, style: context.type.caption),
              ],
            ],
          ),
        ),
        ...trailing,
      ],
    );
  }
}
