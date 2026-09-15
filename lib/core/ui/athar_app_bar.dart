import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';

/// A screen's top bar: back, title (with an optional subtitle) and actions.
class AtharAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AtharAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  static const _height = 60.0;

  @override
  Size get preferredSize => Size.fromHeight(_height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _height,
      titleSpacing: AtharSpace.xxs,
      title: subtitle == null
          ? Text(title)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.caption),
              ],
            ),
      actions: [...?actions, const SizedBox(width: AtharSpace.xs)],
      bottom: bottom,
    );
  }
}
