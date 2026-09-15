import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';
import '../theme/app_theme.dart';
import 'athar_section_header.dart';
import 'athar_tone.dart';

/// Related rows grouped on one surface, separated by hairlines — instead of a
/// card per row.
class AtharListGroup extends StatelessWidget {
  const AtharListGroup({
    super.key,
    this.title,
    this.footer,
    required this.children,
  });

  final String? title;

  /// A short explanation under the group.
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) AtharSectionHeader(title: title!),
        Material(
          color: context.athar.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtharRadius.card),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(
                    height: 1,
                    indent: AtharSpace.md + AtharSize.iconTile + AtharSpace.sm,
                  ),
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AtharSpace.xxs, AtharSpace.xs, AtharSpace.xxs, 0),
            child: Text(footer!, style: context.type.caption),
          ),
      ],
    );
  }
}

/// One row of a [AtharListGroup]: an icon tile, a title with an optional
/// subtitle, and a value, a control or a chevron at the end.
class AtharListRow extends StatelessWidget {
  const AtharListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.tone = AtharTone.brand,
    this.destructive = false,
    this.showChevron,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// A short current value shown at the end, e.g. the chosen language.
  final String? value;

  /// A control at the end, e.g. a switch or a spinner.
  final Widget? trailing;
  final VoidCallback? onTap;
  final AtharTone tone;
  final bool destructive;

  /// Defaults to showing a chevron on tappable rows that open something.
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final iconTone = destructive ? AtharTone.danger : tone;
    final chevron = showChevron ?? (onTap != null && trailing == null);

    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.sm),
            child: Row(
              children: [
                Container(
                  width: AtharSize.iconTile,
                  height: AtharSize.iconTile,
                  decoration: BoxDecoration(
                    color: iconTone.background(context),
                    borderRadius: BorderRadius.circular(AtharRadius.sm),
                  ),
                  child: Icon(icon, size: AtharSize.icon, color: iconTone.foreground(context)),
                ),
                const SizedBox(width: AtharSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.text.titleSmall?.copyWith(
                          color: destructive ? scheme.error : scheme.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: context.type.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: AtharSpace.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: AtharSpace.xs),
                  trailing!,
                ],
                if (chevron) ...[
                  const SizedBox(width: AtharSpace.xxs),
                  Icon(Icons.chevron_right_rounded, size: AtharSize.icon, color: scheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
