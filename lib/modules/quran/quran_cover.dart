import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/quran_surahs.dart';
import '../../core/theme/app_theme.dart';
import 'quran_controller.dart';
import 'quran_index_view.dart';
import 'quran_mood_view.dart';

/// "Page 0" — what the Mushaf opens on, in three parts:
///  1. the reader's statistics;
///  2. where they left off, today's reward and the khatma so far;
///  3. ways into the Mushaf — continuing where they left off, the index,
///     reading by how you feel, a random page and the bookmark.
///
/// Nothing is opened and no reading clock runs until one is chosen. The cover
/// follows the app's language direction; only the Mushaf itself is always
/// right-to-left.
class QuranCover extends GetView<QuranController> {
  const QuranCover({super.key});

  /// Content never stretches wider than this on tablets and in landscape.
  static const double _maxWidth = 720;

  /// "Surah Al-Baqarah · p. 12" for a page.
  static String where(int page) =>
      '${'quran_surah_n'.trParams({'name': surahForPage(page).localizedName})}'
      '  ·  ${'quran_page_short'.trParams({'page': '$page'})}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const _Header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionTitle(text: 'quran_cover_stats'.tr),
                        const SizedBox(height: 12),
                        const _ContinueCard(),
                        const SizedBox(height: 12),
                        const _Stats(),
                        const SizedBox(height: 12),
                        _SectionTitle(text: 'quran_cover_ways'.tr),
                        const SizedBox(height: 12),
                        const _Ways(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back<void>,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              'quran_title'.tr,
              textAlign: TextAlign.center,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Balances the back button so the title sits in the middle.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Where the reader left off, whether today's reward is taken, and how far
/// through the current khatma they are. Continuing is the first of the ways
/// below.
class _ContinueCard extends GetView<QuranController> {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final last = controller.lastReadPage.value;
      final total = controller.totalPages.value;
      final read = controller.khatmaPages.value.clamp(0, total);
      final khatmas = controller.khatmasCompleted.value;

      return Container(
        decoration: BoxDecoration(
          gradient: context.athar.heroGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // A quiet ornament in the corner, on the reading side.
            PositionedDirectional(
              end: -28,
              top: -28,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RewardBadge(
                    done: controller.dailyRewardDone,
                    points: controller.pagePoints.value,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'quran_last_read'.tr,
                        style: context.text.titleSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        QuranCover.where(last),
                        style: context.text.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  const SizedBox(height: 18),
                  Semantics(
                    label: 'quran_khatma_progress'.tr,
                    value: '$read / $total',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'quran_khatma_progress'.tr,
                                style: context.text.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Text(
                              '$read / $total',
                              style: context.text.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? read / total : 0,
                            minHeight: 7,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(
                              context.athar.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (khatmas > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '🏅 ${'quran_khatmas_done'.trParams({'n': '$khatmas'})}',
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Today's reward at a glance: taken, or still waiting for a page to be read.
class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.done, required this.points});

  final bool done;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: done
              ? context.athar.success
              : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done
                ? Colors.white.withValues(alpha: 0.35)
                : context.athar.gold.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: Text(done ? '✅' : '⭐')),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                done
                    ? 'quran_reward_taken'.tr
                    : 'quran_reward_open'.trParams({'points': '$points'}),
                style: context.text.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The five ways into the Mushaf, as a compact list: one column on a phone,
/// two on wider screens. Continuing where the reader left off comes first,
/// across the full width.
class _Ways extends GetView<QuranController> {
  const _Ways();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        Widget sized(Widget tile) => SizedBox(width: width, child: tile);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              child: Obx(() {
                final last = controller.lastReadPage.value;
                return _WayTile(
                  icon: Icons.auto_stories_rounded,
                  color: context.colors.primary,
                  title: 'quran_continue'.tr,
                  subtitle: QuranCover.where(last),
                  highlighted: false,
                  onTap: () => controller.openAt(last),
                );
              }),
            ),
            sized(
              _WayTile(
                icon: Icons.menu_book_rounded,
                color: context.colors.primary,
                title: 'quran_index'.tr,
                subtitle: 'quran_cover_index_sub'.tr,
                onTap: () => Get.to<void>(() => const QuranIndexView()),
              ),
            ),
            sized(
              _WayTile(
                icon: Icons.favorite_rounded,
                color: context.athar.gold,
                title: 'quran_mood'.tr,
                subtitle: 'quran_mood_sub'.tr,
                onTap: QuranMoodView.open,
              ),
            ),
            sized(
              _WayTile(
                icon: Icons.shuffle_rounded,
                color: context.athar.sage,
                title: 'quran_random_page'.tr,
                subtitle: 'quran_cover_random_sub'.tr,
                onTap: controller.randomPage,
              ),
            ),
            sized(
              Obx(() {
                final bookmark = controller.bookmarkPage.value;
                return _WayTile(
                  icon: Icons.bookmark_rounded,
                  color: context.athar.warning,
                  title: 'quran_bookmark'.tr,
                  subtitle: bookmark == null
                      ? 'quran_no_bookmark'.tr
                      : QuranCover.where(bookmark),
                  onTap: bookmark == null
                      ? null
                      : () => controller.openAt(bookmark),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

/// One way into the Mushaf, as a compact row. Dimmed and inert when [onTap] is
/// null — the bookmark before one has been set. [highlighted] fills the row in
/// the primary colour, for continuing where the reader left off.
class _WayTile extends StatelessWidget {
  const _WayTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final muted = highlighted ? Colors.white70 : context.athar.textMuted;

    return Material(
      color: highlighted ? context.colors.primary : context.athar.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlighted
            ? BorderSide.none
            : BorderSide(color: context.colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlighted
                        ? Colors.white.withValues(alpha: 0.18)
                        : color.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: highlighted ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: highlighted ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Mirrors with the text direction, so it points onward.
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress so far: different pages read, Quran points, and minutes of
/// reading.
class _Stats extends GetView<QuranController> {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = [
        ('📖', '${controller.pagesCompleted.value}', 'quran_stat_pages'.tr),
        ('⭐', '${controller.totalPoints.value}', 'quran_stat_points'.tr),
        (
          '⏱️',
          '${controller.totalSeconds.value ~/ 60}',
          'quran_stat_minutes'.tr,
        ),
      ];

      return Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                emoji: stats[i].$1,
                value: stats[i].$2,
                label: stats[i].$3,
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: context.athar.beige,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: context.text.bodySmall?.copyWith(
                color: context.athar.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
