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
                          const SizedBox(height: AtharSpace.xl),
                          AtharSectionHeader(title: 'quran_cover_stats'.tr),
                          const TourTarget(id: TourTargets.quranStats, child: _Stats()),
                          const SizedBox(height: AtharSpace.xl),
                          AtharSectionHeader(title: 'quran_cover_ways'.tr),
                          const TourTarget(id: TourTargets.quranWays, child: _Ways()),
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
                  Text(
                    'quran_last_read'.tr,
                    style: context.text.bodySmall?.copyWith(color: onBrand.withValues(alpha: 0.75)),
                  ),
                  Text(
                    QuranCover.where(last),
                    style: context.text.titleMedium?.copyWith(color: onBrand),
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
          color: done ? athar.success : onBrand.withValues(alpha: 0.16),
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

/// The ways into the Mushaf, as grouped rows.
class _Ways extends GetView<QuranController> {
  const _Ways();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtharListGroup(
          children: [
            Obx(() {
              final last = controller.lastReadPage.value;
              return AtharListRow(
                icon: Icons.auto_stories_rounded,
                title: 'quran_continue'.tr,
                subtitle: QuranCover.where(last),
                onTap: () => controller.openAt(last),
              );
            }),
            // The next page this khatma is still missing, after the last one
            // read — for finishing the khatma without hunting for gaps.
            Obx(() {
              final next = controller.nextUnreadPage();
              return AtharListRow(
                icon: Icons.flag_rounded,
                tone: AtharTone.gold,
                title: 'quran_next_unread'.tr,
                subtitle: next == null ? 'quran_khatma_all_read'.tr : QuranCover.where(next),
                onTap: next == null ? null : () => controller.openAt(next),
              );
            }),
            Obx(() {
              final bookmark = controller.bookmarkPage.value;
              return AtharListRow(
                icon: Icons.bookmark_rounded,
                tone: AtharTone.warning,
                title: 'quran_bookmark'.tr,
                subtitle: bookmark == null ? 'quran_no_bookmark'.tr : QuranCover.where(bookmark),
                onTap: bookmark == null ? null : () => controller.openAt(bookmark),
              );
            }),
          ],
        ),
        const SizedBox(height: AtharSpace.sm),
        AtharListGroup(
          children: [
            AtharListRow(
              icon: Icons.menu_book_rounded,
              title: 'quran_index'.tr,
              subtitle: 'quran_cover_index_sub'.tr,
              onTap: () => Get.to<void>(() => const QuranIndexView()),
            ),
            AtharListRow(
              icon: Icons.insights_rounded,
              title: 'quran_khatma_map'.tr,
              subtitle: 'quran_khatma_map_sub'.tr,
              onTap: () => Get.to<void>(() => const KhatmaProgressView()),
            ),
            AtharListRow(
              icon: Icons.favorite_rounded,
              tone: AtharTone.gold,
              title: 'quran_mood'.tr,
              subtitle: 'quran_mood_sub'.tr,
              onTap: QuranMoodView.open,
            ),
            AtharListRow(
              icon: Icons.shuffle_rounded,
              tone: AtharTone.info,
              title: 'quran_random_page'.tr,
              subtitle: 'quran_cover_random_sub'.tr,
              onTap: controller.randomPage,
            ),
          ],
        ),
      ],
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
                    tone: AtharTone.gold,
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
                padding: EdgeInsets.symmetric(vertical: AtharSpace.md),
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
