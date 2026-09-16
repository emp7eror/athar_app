import 'package:flutter/material.dart';

import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';
import '../theme/app_theme.dart';
import 'athar_section_header.dart';
import 'athar_tone.dart';

/// Related items grouped on one surface and displayed as a responsive grid.
class AtharGridGroup extends StatelessWidget {
  const AtharGridGroup({
    super.key,
    this.title,
    this.footer,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.3,
  });

  final String? title;

  /// A short explanation under the group.
  final String? footer;

  final List<Widget> children;

  /// Number of columns in the grid.
  final int crossAxisCount;

  /// Width / height ratio of each tile.
  final double childAspectRatio;

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
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AtharSpace.sm),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AtharSpace.sm,
              mainAxisSpacing: AtharSpace.sm,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) {
              return children[index];
            },
          ),
        ),

        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AtharSpace.xxs,
              AtharSpace.xs,
              AtharSpace.xxs,
              0,
            ),
            child: Text(
              footer!,
              style: context.type.caption,
            ),
          ),
      ],
    );
  }
}

class AtharGridTile extends StatelessWidget {
  const AtharGridTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.tone = AtharTone.brand,
    this.destructive = false,
    this.isStart = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final AtharTone tone;
  final bool destructive;
  final bool isStart;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    final iconTone = destructive
        ? AtharTone.danger
        : tone;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtharRadius.md),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Large decorative icon in the background.
            isStart? PositionedDirectional(
              start: -20,
              bottom: -25,
              child: IgnorePointer(
                child: Icon(
                  icon,
                  size: 105,
                  color: iconTone.background(context).withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ): PositionedDirectional(
              end: -20,
              bottom: -25,
              child: IgnorePointer(
                child: Icon(
                  icon,
                  size: 105,
                  color: iconTone.background(context).withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AtharSpace.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      color: destructive
                          ? scheme.error
                          : scheme.onSurface,
                    ),
                  ),

                  if (subtitle != null) ...[
                    const SizedBox(height: AtharSpace.xxs),
                    Text(
                      subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.caption,
                    ),
                  ],

                  if (value != null) ...[
                    const SizedBox(height: AtharSpace.xs),
                    Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  if (trailing != null) ...[
                    const SizedBox(height: AtharSpace.xs),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}