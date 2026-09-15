import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';

/// Opens a bottom sheet in Athar's style (drag handle, rounded top, card
/// colour — all from the theme).
Future<T?> showAtharSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}

/// The title block at the top of a sheet.
class AtharSheetHeader extends StatelessWidget {
  const AtharSheetHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AtharSpace.lg, 0, AtharSpace.lg, AtharSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(header: true, child: Text(title, style: context.type.screenTitle)),
                if (subtitle != null) ...[
                  const SizedBox(height: AtharSpace.xxs),
                  Text(subtitle!, style: context.type.caption),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
