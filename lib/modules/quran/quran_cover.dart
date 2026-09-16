import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../core/constants/quran_surahs.dart';
import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../tour/app_tours.dart';
import 'khatma_progress_view.dart';
import 'quran_controller.dart';
import 'quran_index_view.dart';
import 'quran_mood_view.dart';

/// "Page 0" — what the Mushaf opens on: where the reader left off and the
/// khatma so far, their Quran journey in numbers, and the ways in.
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
    return TourAutoStart(
      pageId: TourPages.quran,
      child: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AtharSpace.screen,
                  AtharSpace.xs,
                  AtharSpace.screen,
                  AtharSpace.xxl,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TourTarget(id: TourTargets.quranContinue, child: _ContinueCard()),
                          const SizedBox(height: AtharSpace.lg),
                          // The ways in come before the numbers: on a phone the
                          // index and "by mood" then sit above the fold, and
                          // the journey's totals are what you scroll for.
                          AtharSectionHeader(title: 'quran_cover_ways'.tr),
                          const TourTarget(id: TourTargets.quranWays, child: _Ways()),
                          const SizedBox(height: AtharSpace.lg),
                          AtharSectionHeader(title: 'quran_cover_stats'.tr),
                          const TourTarget(id: TourTargets.quranStats, child: _Stats()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AtharSpace.xs, AtharSpace.xxs, AtharSpace.xs, AtharSpace.xxs),
      child: Row(
        children: [
          AtharIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: Get.back<void>,
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'quran_title'.tr,
                textAlign: TextAlign.center,
                style: context.text.titleLarge,
              ),
            ),
          ),
          // Keeps the back button's width so the title stays centred.
          const SizedBox(
            width: AtharSize.tap,
            child: Center(child: TourHelpButton(pageId: TourPages.quran, style: TourHelpStyle.appBar)),
          ),
        ],
      ),
    );
  }
}

/// Where the reader left off, whether today's reward is taken, and how far
/// through the current khatma they are.
class _ContinueCard extends GetView<QuranController> {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    const onBrand = Colors.white;

    return Obx(() {
      final last = controller.lastReadPage.value;
      final total = controller.totalPages.value;
      final read = controller.khatmaPages.value.clamp(0, total);
      final khatmas = controller.khatmasCompleted.value;

      return AtharCard(
        tone: AtharCardTone.brand,
        padding: EdgeInsets.zero,
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
                  color: onBrand.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AtharSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RewardBadge(done: controller.dailyRewardDone, points: controller.pagePoints.value),
                  const SizedBox(height: AtharSpace.md),
                  Row(
                    children: [
                      Text(
                        'quran_last_read'.tr,
                        style: context.text.bodySmall?.copyWith(color: onBrand.withValues(alpha: 0.75)),
                      ),
                      SizedBox(width: 10,),Text(
                        QuranCover.where(last),
                        style: context.text.bodySmall?.copyWith(color: onBrand),
                      ),
                    ],
                  ),

                  const SizedBox(height: AtharSpace.md),
                  // Opens the khatma in detail: surah by surah, page by page.
                  Semantics(
                    button: true,
                    label: 'quran_khatma_progress'.tr,
                    value: '$read / $total',
                    excludeSemantics: true,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => Get.to<void>(() => const KhatmaProgressView()),
                        borderRadius: BorderRadius.circular(AtharRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AtharSpace.xxs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'quran_khatma_progress'.tr,
                                      style: context.text.bodySmall?.copyWith(
                                        color: onBrand.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$read / $total',
                                    style: context.text.labelLarge?.copyWith(
                                      color: onBrand,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  const SizedBox(width: AtharSpace.xxs),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: AtharSize.iconSm,
                                    color: onBrand.withValues(alpha: 0.75),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AtharSpace.xs),
                              AtharProgressBar(
                                value: total > 0 ? read / total : 0,
                                height: 7,
                                color: context.athar.gold,
                                trackColor: onBrand.withValues(alpha: 0.24),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AtharSpace.md),
                  const _ResumeActions(),
                  if (khatmas > 0) ...[
                    const SizedBox(height: AtharSpace.sm),
                    Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: AtharSize.iconSm + 2, color: context.athar.gold),
                        const SizedBox(width: AtharSpace.xs),
                        Flexible(
                          child: Text(
                            'quran_khatmas_done'.trParams({'n': '$khatmas'}),
                            style: context.text.bodySmall?.copyWith(color: onBrand),
                          ),
                        ),
                      ],
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
    const onBrand = Colors.white;
    final athar = context.athar;

    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: AtharMotion.slow,
        padding: const EdgeInsets.symmetric(horizontal: AtharSpace.sm, vertical: AtharSpace.xxs + 2),
        decoration: BoxDecoration(
          color: onBrand.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AtharRadius.pill),
          border: Border.all(
            color: done ? onBrand.withValues(alpha: 0.35) : athar.gold.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.star_rounded,
              size: AtharSize.iconSm,
              color: done ? onBrand : athar.gold,
            ),
            const SizedBox(width: AtharSpace.xs),
            Flexible(
              child: Text(
                done ? 'quran_reward_taken'.tr : 'quran_reward_open'.trParams({'points': '$points'}),
                style: context.text.labelMedium?.copyWith(color: onBrand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three ways to resume, as buttons on the continue card itself — the
/// card already carries the pages they lead to, so they need no rows of their
/// own. A way with nowhere to go (no bookmark, khatma finished) stays visible
/// but quiet rather than disappearing.
class _ResumeActions extends GetView<QuranController> {
  const _ResumeActions();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final next = controller.nextUnreadPage();

      return Row(
        children: [
          Expanded(
            child: _ResumeAction(
              icon: Icons.auto_stories_rounded,
              label: 'quran_continue'.tr,
              onTap: () => controller.openAt(controller.lastReadPage.value),
            ),
          ),
          const SizedBox(width: AtharSpace.xs),
          Expanded(
            child: _ResumeAction(
              icon: Icons.flag_rounded,
              label: next == null ? 'quran_khatma_all_read'.tr : 'quran_next_unread'.tr,
              page: next,
              onTap: next == null ? null : () => controller.openAt(next),
            ),
          ),
          const SizedBox(width: AtharSpace.xs),
          // The khatma in detail — surah by surah, juz by juz, page by page.
          Expanded(
            child: _ResumeAction(
              icon: Icons.insights_rounded,
              label: 'quran_khatma_map'.tr,
              onTap: () => Get.to<void>(() => const KhatmaProgressView()),
            ),
          ),
        ],
      );
    });
  }
}

class _ResumeAction extends StatelessWidget {
  const _ResumeAction({required this.icon, required this.label, required this.onTap, this.page});

  final IconData icon;
  final String label;

  /// The page it opens, shown under the label when there is one.
  final int? page;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const onBrand = Colors.white;
    final enabled = onTap != null;
    final ink = onBrand.withValues(alpha: enabled ? 1 : 0.55);

    return MergeSemantics(
      child: Material(
        color: onBrand.withValues(alpha: enabled ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(AtharRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AtharRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtharSpace.xs, vertical: AtharSpace.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AtharSize.iconSm, color: ink),
                const SizedBox(height: AtharSpace.xxs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(color: ink),
                ),
                if (page != null)
                  Text(
                    'quran_page_short'.trParams({'page': '$page'}),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: context.text.labelSmall?.copyWith(
                      color: onBrand.withValues(alpha: 0.7),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ways into the Mushaf: one strip, since none of them carries a page —
/// they only open a way of choosing one.
class _Ways extends GetView<QuranController> {
  const _Ways();

  @override
  Widget build(BuildContext context) {
    return AtharCard(
      padding: const EdgeInsets.symmetric(vertical: AtharSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _WayTile(
              icon: Icons.menu_book_rounded,
              label: 'quran_index'.tr,
              onTap: () => Get.to<void>(() => const QuranIndexView()),
            ),
          ),
          // The khatma in detail keeps its place on the card's progress bar;
          // this slot goes to the page the reader saved themselves.
          Expanded(
            child: Obx(() {
              final bookmark = controller.bookmarkPage.value;
              return _WayTile(
                icon: Icons.bookmark_rounded,
                tone: AtharTone.warning,
                label: bookmark == null ? 'quran_no_bookmark'.tr : 'quran_bookmark'.tr,
                onTap: bookmark == null ? null : () => controller.openAt(bookmark),
              );
            }),
          ),
          Expanded(
            child: _WayTile(
              icon: Icons.favorite_rounded,
              // tone: AtharTone.gold,
              label: 'quran_mood'.tr,
              onTap: QuranMoodView.open,
            ),
          ),
          Expanded(
            child: _WayTile(
              icon: Icons.shuffle_rounded,
              // tone: AtharTone.info,
              label: 'quran_random_page'.tr,
              onTap: controller.randomPage,
            ),
          ),
        ],
      ),
    );
  }
}

class _WayTile extends StatelessWidget {
  const _WayTile({required this.icon, required this.label, required this.onTap, this.tone = AtharTone.brand});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final AtharTone tone;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtharRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AtharSpace.xxs, vertical: AtharSpace.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AtharSize.iconTile,
                height: AtharSize.iconTile,
                decoration: BoxDecoration(
                  color: enabled ? tone.background(context) : context.colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AtharSize.iconSm,
                  color: enabled ? tone.foreground(context) : context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AtharSpace.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: enabled ? context.colors.onSurface : context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress so far: pages read, Quran points, minutes, and — once the server
/// has the per-page counts — words and letters.
class _Stats extends GetView<QuranController> {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final number = NumberFormat.decimalPattern(Get.locale?.languageCode);

      final stats = <(IconData, String, String)>[
        (Icons.auto_stories_rounded, '${controller.pagesCompleted.value}', 'quran_stat_pages'.tr),
        (Icons.star_rounded, '${controller.totalPoints.value}', 'quran_stat_points'.tr),
        (Icons.timer_rounded, '${controller.totalSeconds.value ~/ 60}', 'quran_stat_minutes'.tr),
      ];
      final words = <(IconData, String, String)>[
        if (controller.wordCountsAvailable.value) ...[
          (Icons.notes_rounded, number.format(controller.wordsRead.value), 'quran_stat_words'.tr),
          (Icons.text_fields_rounded, number.format(controller.lettersRead.value), 'quran_stat_letters'.tr),
        ],
      ];

      Widget row(List<(IconData, String, String)> items) => Row(
        children: [
          for (final item in items)
            Expanded(
              child: AtharStat(
                icon: item.$1,
                tone: AtharTone.brand,
                value: item.$2,
                label: item.$3,
                center: true,
              ),
            ),
        ],
      );

      return AtharCard(
        child: Column(
          children: [
            row(stats),
            if (words.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AtharSpace.sm),
                child: Divider(height: 1),
              ),
              row(words),
            ],
          ],
        ),
      );
    });
  }
}
