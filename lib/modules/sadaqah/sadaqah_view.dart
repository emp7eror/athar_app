import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'sadaqah_category_view.dart';
import 'sadaqah_controller.dart';
import 'sadaqah_models.dart';
import 'sadaqah_widgets.dart';

/// صدقة, opened from its tile on Home: the user's totals and today's points,
/// then the categories as a grid of three columns. A category opens its deeds.
class SadaqahView extends GetView<SadaqahController> {
  const SadaqahView({super.key});

  static const _columns = 3;

  static Future<void> open() async {
    // Registered with Home; put here too so a page opened any other way works.
    if (!Get.isRegistered<SadaqahController>()) Get.put(SadaqahController());
    await Get.to(() => const SadaqahView());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AtharAppBar(title: 'sadaqah_title'.tr),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          // Pull to refresh works even while the content is short.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AtharSpace.screen,
            AtharSpace.md,
            AtharSpace.screen,
            AtharSpace.xl,
          ),
          children: [
            // Totals first, then the categories.
            const _HeroCard(),
            const SizedBox(height: AtharSpace.lg),
            AtharSectionHeader(title: 'sadaqah_categories_title'.tr),
            Obx(() {
              if (controller.loading.value) {
                return const _GridSkeleton(columns: _columns);
              }

              final error = controller.loadError.value;
              if (error != null) {
                return SadaqahPanel(
                  child: AtharErrorState(
                    message: error,
                    onRetry: controller.load,
                  ),
                );
              }
              if (controller.categories.isEmpty) {
                return SadaqahPanel(
                  child: AtharEmptyState(
                    icon: SadaqahIcons.fallback,
                    title: 'sadaqah_empty_title'.tr,
                    message: 'sadaqah_empty_message'.tr,
                  ),
                );
              }

              return _Grid(
                columns: _columns,
                children: [
                  for (final c in controller.categories)
                    _CategoryTile(category: c),
                ],
              );
            }),
            const SizedBox(height: AtharSpace.md),
            const SadaqahPointsNote(),
          ],
        ),
      ),
    );
  }
}

/// The user's totals — how many sadaqat, and the points they earned — on the
/// app's card surface, with today's points as a pill beneath.
class _HeroCard extends GetView<SadaqahController> {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.stats.value;
      if (stats == null) {
        return controller.loading.value
            ? const AtharSkeleton(height: 168, radius: AtharRadius.card)
            : const SizedBox.shrink();
      }

      final scheme = context.colors;
      final rewarded = controller.rewardedToday.value;
      final pillColor = rewarded
          ? context.athar.success
          : AtharTone.brand.foreground(context);

      return Container(
        clipBehavior: Clip.antiAlias,
        // The same surface and border as the app's other cards.
        decoration: BoxDecoration(
          color: context.athar.card,
          borderRadius: BorderRadius.circular(AtharRadius.card),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -24,
              bottom: -28,
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 140,
                color: AtharTone.brand
                    .foreground(context)
                    .withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AtharSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('sadaqah_subtitle'.tr, style: context.type.bodyStrong),
                  const SizedBox(height: AtharSpace.md),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _Figure(
                            icon: Icons.volunteer_activism_rounded,
                            value: stats.total,
                            label: 'sadaqah_stat_total'.tr,
                            tone: AtharTone.brand,
                          ),
                        ),
                        VerticalDivider(
                          width: AtharSpace.lg,
                          thickness: 1,
                          color: scheme.outlineVariant,
                        ),
                        Expanded(
                          child: _Figure(
                            icon: Icons.star_rounded,
                            value: stats.points,
                            label: 'sadaqah_stat_points'.tr,
                            tone: AtharTone.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AtharSpace.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AtharSpace.sm,
                      vertical: AtharSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AtharRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rewarded
                              ? Icons.check_circle_rounded
                              : Icons.wb_sunny_rounded,
                          size: AtharSize.iconSm,
                          color: pillColor,
                        ),
                        const SizedBox(width: AtharSpace.xxs),
                        Flexible(
                          child: Text(
                            rewarded
                                ? 'sadaqah_today_rewarded'.trParams({
                                    'points': '${controller.pointsToday.value}',
                                  })
                                : 'sadaqah_today_open'.tr,
                            style: context.text.labelMedium?.copyWith(
                              color: pillColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// One figure on the hero card: its icon in a soft circle of [tone], the
/// number, its label.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.icon,
    required this.value,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final int value;
  final String label;
  final AtharTone tone;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.background(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: tone.foreground(context)),
          ),
          const SizedBox(width: AtharSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: _CountUp(
                    value: value,
                    style: context.type.statValue.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A number that counts up to [value] — from zero when the page opens, from
/// the last figure when it changes. Shown at once when motion is reduced.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('${v.round()}', semanticsLabel: '$value', style: style),
    );
  }
}

/// Rows of [columns] equal cells, each row as tall as its tallest tile — the
/// same build as the practices grid on Home.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var j = 0; j < columns; j++) {
        if (j > 0) cells.add(const SizedBox(width: AtharSpace.sm));
        final index = i + j;
        cells.add(
          index < children.length
              ? Expanded(child: children[index])
              : const Spacer(),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AtharSpace.sm));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// A category: its icon in its colour, its name, and how many deeds it holds.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final SadaqahCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final radius = BorderRadius.circular(AtharRadius.card);
    final count = 'sadaqah_deeds_count'.trParams({
      'count': '${category.deedsCount}',
    });

    return Semantics(
      button: true,
      label: '${category.name}، $count',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: context.athar.card,
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: InkWell(
            onTap: () => SadaqahCategoryView.open(category),
            splashColor: color.withValues(alpha: 0.18),
            highlightColor: color.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AtharSpace.xs,
                AtharSpace.md,
                AtharSpace.xs,
                AtharSpace.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      SadaqahIcons.of(category.icon),
                      size: 26,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AtharSpace.xs),
                  Text(
                    category.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: context.type.caption,
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

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'sadaqah_loading'.tr,
      child: _Grid(
        columns: columns,
        children: [
          for (var i = 0; i < columns * 3; i++)
            const AtharSkeleton(height: 120, radius: AtharRadius.card),
        ],
      ),
    );
  }
}
