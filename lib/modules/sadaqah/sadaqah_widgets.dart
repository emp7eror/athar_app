import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'sadaqah_deed_sheet.dart';
import 'sadaqah_models.dart';

/// A deed in a category's list: its icon, title, a line of description and
/// its points. Opens the deed in full.
class SadaqahDeedCard extends StatelessWidget {
  const SadaqahDeedCard({
    super.key,
    required this.deed,
    required this.color,
    required this.recorded,
  });

  final SadaqahDeed deed;
  final Color color;

  /// Recorded today — shown by a mark and words, never by colour alone.
  final bool recorded;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final success = context.athar.success;

    return Semantics(
      button: true,
      label: [
        deed.title,
        'sadaqah_points_value'.trParams({'points': '${deed.points}'}),
        if (recorded) 'sadaqah_recorded_today'.tr,
      ].join('، '),
      excludeSemantics: true,
      child: Material(
        color: context.athar.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtharRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => SadaqahDeedSheet.open(context, deed),
          child: Padding(
            padding: const EdgeInsets.all(AtharSpace.sm),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    SadaqahIcons.of(deed.icon),
                    size: AtharSize.iconLg,
                    color: color,
                  ),
                ),
                const SizedBox(width: AtharSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        deed.title,
                        style: context.type.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deed.description,
                        style: context.type.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (recorded) ...[
                        const SizedBox(height: AtharSpace.xxs),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: AtharSize.iconSm,
                              color: success,
                            ),
                            const SizedBox(width: AtharSpace.xxs),
                            Text(
                              'sadaqah_recorded_today'.tr,
                              style: context.text.labelSmall?.copyWith(
                                color: success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AtharSpace.xs),
                SadaqahPointsPill(points: deed.points, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A deed's illustrative points.
class SadaqahPointsPill extends StatelessWidget {
  const SadaqahPointsPill({
    super.key,
    required this.points,
    required this.color,
  });

  final int points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtharSpace.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AtharRadius.pill),
      ),
      child: Text(
        '+$points',
        style: context.text.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Points are motivational, and counted once a day: said wherever they're shown.
class SadaqahPointsNote extends StatelessWidget {
  const SadaqahPointsNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline_rounded,
            size: AtharSize.iconSm,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AtharSpace.xxs),
        Expanded(
          child: Text('sadaqah_points_note'.tr, style: context.type.caption),
        ),
      ],
    );
  }
}

/// A card-coloured surface for empty and error states.
class SadaqahPanel extends StatelessWidget {
  const SadaqahPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.athar.card,
        borderRadius: BorderRadius.circular(AtharRadius.card),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: child,
    );
  }
}
