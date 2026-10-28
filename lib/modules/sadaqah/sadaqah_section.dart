import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'sadaqah_controller.dart';
import 'sadaqah_deed_sheet.dart';
import 'sadaqah_models.dart';

/// صدقة on Home, under the practices: the categories as coloured chips, and
/// the chosen category's deeds as cards. A card opens the deed in full, where
/// it can be recorded.
class SadaqahSection extends GetView<SadaqahController> {
  const SadaqahSection({super.key});

  /// Deeds shown before "show more", so the section doesn't take over Home.
  static const _collapsedCount = 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: AtharSpace.sm),
        Obx(() {
          if (controller.loading.value) return const _Skeleton();

          final error = controller.loadError.value;
          if (error != null) {
            return _Panel(
              child: AtharErrorState(message: error, onRetry: controller.load),
            );
          }
          if (controller.categories.isEmpty) {
            return _Panel(
              child: AtharEmptyState(
                icon: SadaqahIcons.fallback,
                title: 'sadaqah_empty_title'.tr,
                message: 'sadaqah_empty_message'.tr,
              ),
            );
          }

          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CategoryChips(),
              SizedBox(height: AtharSpace.sm),
              _DeedList(collapsedCount: _collapsedCount),
            ],
          );
        }),
        const SizedBox(height: AtharSpace.xs),
        const SadaqahPointsNote(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Title, subtitle and today's points
// ─────────────────────────────────────────────────────────────────────────
class _Header extends GetView<SadaqahController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final accent = AtharTone.gold.foreground(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AtharTone.gold.background(context),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.volunteer_activism_rounded,
            size: AtharSize.iconLg,
            color: accent,
          ),
        ),
        const SizedBox(width: AtharSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'sadaqah_title'.tr,
                  style: context.type.sectionTitle,
                ),
              ),
              Text('sadaqah_subtitle'.tr, style: context.type.caption),
            ],
          ),
        ),
        Obx(() {
          final daily = controller.dailyPoints.value;
          if (daily == 0) return const SizedBox.shrink();
          return Semantics(
            label: 'sadaqah_points_today_label'.trParams({
              'points': '${controller.pointsToday.value}',
              'limit': '$daily',
            }),
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AtharSpace.xs,
                vertical: AtharSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: AtharTone.gold.background(context),
                borderRadius: BorderRadius.circular(AtharRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: AtharSize.iconSm,
                    color: accent,
                  ),
                  const SizedBox(width: AtharSpace.xxs),
                  Text(
                    '${controller.pointsToday.value}/$daily',
                    style: context.text.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Categories, scrolling sideways, each in its own colour
// ─────────────────────────────────────────────────────────────────────────
class _CategoryChips extends GetView<SadaqahController> {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Obx(() {
        final selected = controller.selectedKey.value;
        final categories = controller.categories;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          // Lets the chips run to the screen's edge instead of stopping at
          // the page's padding.
          clipBehavior: Clip.none,
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: AtharSpace.xs),
          itemBuilder: (_, i) => _CategoryChip(
            category: categories[i],
            selected: categories[i].key == selected,
            onTap: () => controller.select(categories[i].key),
          ),
        );
      }),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SadaqahCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final foreground = selected ? Colors.white : color;

    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AtharMotion.base,
        curve: AtharMotion.standard,
        decoration: ShapeDecoration(
          color: selected ? color : color.withValues(alpha: 0.10),
          shape: StadiumBorder(
            side: BorderSide(
              color: color.withValues(alpha: selected ? 1 : 0.35),
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AtharSpace.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    SadaqahIcons.of(category.icon),
                    size: AtharSize.iconSm + 2,
                    color: foreground,
                  ),
                  const SizedBox(width: AtharSpace.xs),
                  Text(
                    category.name,
                    style: context.text.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// The chosen category's deeds
// ─────────────────────────────────────────────────────────────────────────
class _DeedList extends StatefulWidget {
  const _DeedList({required this.collapsedCount});

  final int collapsedCount;

  @override
  State<_DeedList> createState() => _DeedListState();
}

class _DeedListState extends State<_DeedList> {
  final controller = Get.find<SadaqahController>();
  bool _expanded = false;
  late final Worker _categoryWatch;

  @override
  void initState() {
    super.initState();
    // A new category starts collapsed again.
    _categoryWatch = ever(
      controller.selectedKey,
      (_) => setState(() => _expanded = false),
    );
  }

  @override
  void dispose() {
    _categoryWatch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final deeds = controller.visibleDeeds;
      final category = controller.selected;
      // Read here so a recorded deed's mark updates at once.
      final recorded = controller.recordedToday.toSet();

      final Widget content;
      if (deeds.isEmpty) {
        content = _Panel(
          key: ValueKey('empty-${category?.key}'),
          child: AtharEmptyState(
            icon: SadaqahIcons.of(category?.icon ?? ''),
            title: 'sadaqah_category_empty'.tr,
            message: 'sadaqah_category_empty_message'.tr,
          ),
        );
      } else {
        final shown = _expanded
            ? deeds
            : deeds.take(widget.collapsedCount).toList();
        final hidden = deeds.length - shown.length;
        content = Column(
          key: ValueKey(category?.key),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final deed in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: AtharSpace.xs),
                child: _DeedCard(
                  deed: deed,
                  color: category?.color ?? context.colors.primary,
                  recorded: recorded.contains(deed.id),
                ),
              ),
            if (hidden > 0 || _expanded && deeds.length > widget.collapsedCount)
              Align(
                alignment: AlignmentDirectional.center,
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _expanded
                        ? 'sadaqah_show_less'.tr
                        : 'sadaqah_show_more'.trParams({'count': '$hidden'}),
                  ),
                ),
              ),
          ],
        );
      }

      return AnimatedSwitcher(
        duration: AtharMotion.base,
        switchInCurve: AtharMotion.standard,
        child: content,
      );
    });
  }
}

class _DeedCard extends StatelessWidget {
  const _DeedCard({
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
    final radius = BorderRadius.circular(AtharRadius.card);

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
          borderRadius: radius,
          side: BorderSide(
            color: recorded
                ? success.withValues(alpha: 0.5)
                : scheme.outlineVariant,
          ),
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

/// Points are motivational: said wherever they're shown.
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

/// A card-coloured surface for the section's empty and error states.
class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.child});

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

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'sadaqah_loading'.tr,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtharSkeleton(width: 96, height: 40, radius: AtharRadius.pill),
              SizedBox(width: AtharSpace.xs),
              AtharSkeleton(width: 110, height: 40, radius: AtharRadius.pill),
              SizedBox(width: AtharSpace.xs),
              Expanded(
                child: AtharSkeleton(height: 40, radius: AtharRadius.pill),
              ),
            ],
          ),
          SizedBox(height: AtharSpace.sm),
          AtharSkeleton(height: 72, radius: AtharRadius.card),
          SizedBox(height: AtharSpace.xs),
          AtharSkeleton(height: 72, radius: AtharRadius.card),
          SizedBox(height: AtharSpace.xs),
          AtharSkeleton(height: 72, radius: AtharRadius.card),
        ],
      ),
    );
  }
}
