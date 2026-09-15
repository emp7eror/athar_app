import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/framed_avatar.dart';
import '../profile_preview/profile_preview_modal.dart';
import '../tour/app_tours.dart';
import 'leaderboard_controller.dart';

/// Which number a row shows — the tab (points or streak) and, for points, the
/// period (this month or all time).
enum _Metric { score, totalPoints, streak }

int _valueOf(LeaderboardEntry e, _Metric metric) => switch (metric) {
      _Metric.streak => e.currentStreak,
      _Metric.totalPoints => e.totalPoints,
      _Metric.score => e.score,
    };

IconData _iconOf(_Metric metric) =>
    metric == _Metric.streak ? Icons.local_fire_department_rounded : Icons.star_rounded;

/// The leaderboard: what to rank by and among whom, the top three on a podium,
/// then everyone else — with your own place always visible.
class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

  /// Room under the content for the floating nav bar.
  static const _navClearance = 160.0;

  int get myId => (Get.find<StorageProvider>().cachedUser?['id'] as num?)?.toInt() ?? -1;

  @override
  Widget build(BuildContext context) {
    final isAr = Get.find<LocalizationController>().isRtl;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, 0),
                child: AtharPageHeader(
                  title: 'leaderboard'.tr,
                  trailing: const [TourHelpButton(pageId: TourPages.leaderboard)],
                ),
              ),
              const SizedBox(height: AtharSpace.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AtharSpace.screen),
                child: Column(
                  children: [
                    // What the ranking is based on.
                    TourTarget(
                      id: TourTargets.leaderboardMetric,
                      child: Obx(
                        () => AtharSegmented<String>(
                          selected: controller.tab.value,
                          onChanged: controller.switchTab,
                          segments: [
                            AtharSegment(value: 'points', label: 'points_tab'.tr, icon: Icons.star_rounded),
                            AtharSegment(
                              value: 'streak',
                              label: 'streaks_tab'.tr,
                              icon: Icons.local_fire_department_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    // Period only affects points — streaks are always all-time
                    // on the backend — so it's hidden for streaks.
                    TourTarget(
                      id: TourTargets.leaderboardFilters,
                      child: Obx(
                        () => Row(
                          children: [
                            if (controller.tab.value != 'streak') ...[
                              Expanded(
                                child: AtharSegmented<String>(
                                  selected: controller.period.value,
                                  onChanged: controller.switchPeriod,
                                  segments: [
                                    AtharSegment(value: 'current_month', label: 'leaderboard_current_month'.tr),
                                    AtharSegment(value: 'all', label: 'leaderboard_all_time'.tr),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AtharSpace.xs),
                            ],
                            Expanded(
                              child: AtharSegmented<String>(
                                selected: controller.scope.value,
                                onChanged: controller.switchScope,
                                segments: [
                                  AtharSegment(value: 'global', label: 'leaderboard_global'.tr),
                                  AtharSegment(value: 'friends', label: 'leaderboard_friends'.tr),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AtharSpace.xs),
              Expanded(
                child: Obx(() {
                  final rankings = controller.rankings;
                  final padding = const EdgeInsets.fromLTRB(
                    AtharSpace.screen,
                    AtharSpace.sm,
                    AtharSpace.screen,
                    _navClearance,
                  );

                  // Placeholders only on the first load; later reloads keep
                  // the old rows, dimmed, so switching filters doesn't flicker.
                  if (controller.loading.value && rankings.isEmpty) {
                    return ListView(
                      padding: padding,
                      children: [
                        for (var i = 0; i < 6; i++)
                          const Padding(
                            padding: EdgeInsets.only(bottom: AtharSpace.xs),
                            child: AtharSkeleton(height: 60, radius: AtharRadius.card),
                          ),
                      ],
                    );
                  }
                  if (rankings.isEmpty) {
                    return ListView(
                      padding: padding,
                      children: [
                        const SizedBox(height: AtharSpace.xl),
                        AtharEmptyState(icon: Icons.emoji_events_rounded, title: 'leaderboard_empty'.tr),
                      ],
                    );
                  }

                  final metric = controller.tab.value == 'streak'
                      ? _Metric.streak
                      : controller.period.value == 'all'
                          ? _Metric.totalPoints
                          : _Metric.score;
                  final hasPodium = rankings.length >= 3;
                  final rest = hasPodium ? rankings.skip(3).toList() : rankings.toList();
                  final me = controller.me.value;
                  final meListed = rankings.any((e) => e.id == myId);

                  return AnimatedOpacity(
                    opacity: controller.loading.value ? 0.5 : 1,
                    duration: AtharMotion.base,
                    child: ListView(
                      padding: padding,
                      children: [
                        if (hasPodium)
                          TourTarget(
                            id: TourTargets.leaderboardFirst,
                            child: _Podium(entries: rankings.take(3).toList(), metric: metric, myId: myId),
                          ),
                        if (rest.isNotEmpty) ...[
                          if (hasPodium) const SizedBox(height: AtharSpace.lg),
                          AtharListGroup(
                            children: [
                              for (final (i, e) in rest.indexed)
                                !hasPodium && i == 0
                                    ? TourTarget(
                                        id: TourTargets.leaderboardFirst,
                                        child: _RankRow(entry: e, metric: metric, isMe: e.id == myId, isAr: isAr),
                                      )
                                    : _RankRow(entry: e, metric: metric, isMe: e.id == myId, isAr: isAr),
                            ],
                          ),
                        ],
                        if (me != null && !meListed) ...[
                          const SizedBox(height: AtharSpace.lg),
                          AtharListGroup(
                            title: 'leaderboard_your_rank'.tr,
                            children: [_RankRow(entry: me, metric: metric, isMe: true, isAr: isAr)],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The top three, second and third either side of first.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.metric, required this.myId});

  final List<LeaderboardEntry> entries;
  final _Metric metric;
  final int myId;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumPlace(entry: entries[1], place: 2, metric: metric, isMe: entries[1].id == myId)),
        Expanded(child: _PodiumPlace(entry: entries[0], place: 1, metric: metric, isMe: entries[0].id == myId)),
        Expanded(child: _PodiumPlace(entry: entries[2], place: 3, metric: metric, isMe: entries[2].id == myId)),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({required this.entry, required this.place, required this.metric, required this.isMe});

  final LeaderboardEntry entry;
  final int place;
  final _Metric metric;
  final bool isMe;

  /// Medal tints for second and third; first uses the brand gold.
  static const _silver = Color(0xFFB9C0C7);
  static const _bronze = Color(0xFFC08A5B);

  @override
  Widget build(BuildContext context) {
    final medal = switch (place) {
      1 => context.athar.gold,
      2 => _silver,
      _ => _bronze,
    };
    final stepHeight = switch (place) {
      1 => 72.0,
      2 => 52.0,
      _ => 36.0,
    };

    return Semantics(
      button: true,
      label: '${'rank'.tr} $place, ${entry.name}, ${_valueOf(entry, metric)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => openProfilePreview(entry.id, rank: entry.rank),
        borderRadius: BorderRadius.circular(AtharRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AtharSpace.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  FramedAvatar(
                    name: entry.name,
                    avatarUrl: entry.avatarUrl,
                    frameAsset: entry.level?.frame,
                    level: entry.level?.level,
                    radius: place == 1 ? 20 : 16,
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: medal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                      child: Text(
                        '$place',
                        style: context.text.labelMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AtharSpace.sm),
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.text.titleSmall?.copyWith(color: isMe ? context.colors.primary : null),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconOf(metric), size: AtharSize.iconSm, color: context.athar.gold),
                  const SizedBox(width: 2),
                  Text(
                    '${_valueOf(entry, metric)}',
                    style: context.text.labelLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
              const SizedBox(height: AtharSpace.xs),
              Container(
                height: stepHeight,
                decoration: BoxDecoration(
                  color: medal.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AtharRadius.md)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.metric, required this.isMe, required this.isAr});

  final LeaderboardEntry entry;
  final _Metric metric;
  final bool isMe;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final title = entry.level == null ? '' : entry.level!.displayName(isAr);

    return Material(
      color: isMe ? scheme.primaryContainer.withValues(alpha: 0.55) : Colors.transparent,
      child: InkWell(
        onTap: () => openProfilePreview(entry.id, rank: entry.rank),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.xs),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${entry.rank}',
                  textAlign: TextAlign.center,
                  style: context.text.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: AtharSpace.xs),
              FramedAvatar(
                name: entry.name,
                avatarUrl: entry.avatarUrl,
                frameAsset: entry.level?.frame,
                level: entry.level?.level,
                radius: 13,
                glow: false,
              ),
              const SizedBox(width: AtharSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: AtharSpace.xs),
                          AtharBadge(label: 'leaderboard_you'.tr, tone: AtharTone.brand),
                        ],
                      ],
                    ),
                    if (title.isNotEmpty)
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.caption),
                  ],
                ),
              ),
              const SizedBox(width: AtharSpace.xs),
              Text(
                '${_valueOf(entry, metric)}',
                style: context.text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(width: AtharSpace.xxs),
              Icon(_iconOf(metric), size: AtharSize.iconSm, color: context.athar.gold),
            ],
          ),
        ),
      ),
    );
  }
}
