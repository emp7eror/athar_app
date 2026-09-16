import 'package:athar/core/ui/athar_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../../data/models/prayer_log_model.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/framed_avatar.dart';
import '../dhikr/dhikr_binding.dart';
import '../dhikr/dhikr_view.dart';
import '../quran/quran_binding.dart';
import '../quran/quran_view.dart';
import '../settings/settings_view.dart';
import '../shell/shell_view.dart';
import '../tour/app_tours.dart';
import 'home_controller.dart';
import 'prayer_sky_theme.dart';
import 'prayer_visual_theme.dart';

/// Home, in order of what matters now: today's prayers — the next one
/// highlighted with its countdown — then the day's other practices. The top
/// of the page takes on the sky of the prayer that comes next.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  /// Room under the content for the floating nav bar and the AI button on it.
  static const _navClearance = 160.0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every prayer's sky is dark behind the status bar.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            const _SkyBackdrop(),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: controller.refreshAll,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, _navClearance),
                  // Keeps the whole page built so tour steps can scroll to any part.
                  scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
                  children: const [
                    _Header(),
                    SizedBox(height: AtharSpace.lg),
                    TourTarget(id: TourTargets.homeNextPrayer, child: _TodaySummary()),
                    SizedBox(height: AtharSpace.lg),
                    TourTarget(id: TourTargets.homePrayers, child: _PrayerList()),
                    SizedBox(height: AtharSpace.md),
                    TourTarget(id: TourTargets.homePractices, child: _Practices()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// The sky of the next prayer, fading into the page
// ─────────────────────────────────────────────────────────────────────────
class _SkyBackdrop extends GetView<HomeController> {
  const _SkyBackdrop();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final ground = Theme.of(context).scaffoldBackgroundColor;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: top + 300,
      child: IgnorePointer(
        child: Obx(() {
          final sky = PrayerSkyTheme.of(controller.currentPrayerKey.value);
          return Stack(
            fit: StackFit.expand,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: sky.colors.length == 2 ? [...sky.colors, sky.colors.last] : sky.colors,
                  ),
                ),
              ),
              CustomPaint(painter: SkyStarsPainter(count: sky.stars)),
              PositionedDirectional(
                end: -30,
                top: top + AtharSpace.xl,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Icon(sky.watermark, key: ValueKey(sky.watermark), size: 150, color: Colors.white.withValues(alpha: 0.10)),
                ),
              ),
              // Fades into the page so the list sits on plain ground.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1],
                    colors: [ground.withValues(alpha: 0), ground],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Header: who you are, help and settings — light, on the sky
// ─────────────────────────────────────────────────────────────────────────
class _Header extends GetView<HomeController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    const onSky = Colors.white;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TourTarget(
              id: TourTargets.homeProfile,
              child: Semantics(
                button: true,
                label: 'profile'.tr,
                child: InkWell(
                  // The avatar and name open the Profile tab.
                  onTap: () => Get.find<ShellController>().index.value = 4,
                  borderRadius: BorderRadius.circular(AtharRadius.pill),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, AtharSpace.xxs, AtharSpace.sm, AtharSpace.xxs),
                    child: Obx(() {
                      final level = controller.level.value;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FramedAvatar(
                            name: controller.userName.value,
                            avatarUrl: controller.avatarUrl.value,
                            frameAsset: level?.frame,
                            level: level?.level,
                            radius: 12,
                            backgroundColor: context.athar.brand,
                          ),
                          const SizedBox(width: AtharSpace.sm),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.userName.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.type.sectionTitle.copyWith(color: onSky),
                                ),
                                if (level != null)
                                  Text(
                                    level.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodySmall?.copyWith(color: onSky.withValues(alpha: 0.8)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Replays this page's product tour; drawn light for the sky.
        Theme(
          data: Theme.of(context).copyWith(colorScheme: context.colors.copyWith(primary: onSky)),
          child: const TourHelpButton(pageId: TourPages.home),
        ),
        TourTarget(
          id: TourTargets.homeSettings,
          child: AtharIconButton(
            icon: Icons.settings_rounded,
            tooltip: 'settings'.tr,
            color: onSky,
            onPressed: () => Get.to(() => const SettingsView()),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Today: how far the day has come, and where
// ─────────────────────────────────────────────────────────────────────────
class _TodaySummary extends GetView<HomeController> {
  const _TodaySummary();

  @override
  Widget build(BuildContext context) {
    const onSky = Colors.white;

    return Obx(() {
      final items = controller.checklist;
      final done = items.where((i) => i.isCompleted).length;
      final total = items.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mosque_outlined, size: 18,color: onSky,),
                              const SizedBox(width: 6),
                              Text('next_prayer'.tr, style: context.text.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Obx(
                            () => Text(
                              controller.nextPrayerKey.value.isEmpty ? '—' : controller.nextPrayerKey.value.tr,
                              style: context.text.headlineMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ),
                          Obx(
                            () => Text(
                              controller.countdown.value,
                              style: context.text.displaySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: 0,color: onSky.withValues(alpha: 0.80)),
                            ),
                          ),
                          Material(
                            color: onSky.withValues(alpha: 0.14),
                            shape: const StadiumBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Get.to(() => const SettingsView()),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 36),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AtharSpace.sm),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: AtharSize.iconSm, color: onSky),
                                      const SizedBox(width: AtharSpace.xxs),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 140),
                                        child: Text(
                                          controller.locationLabel.value.tr,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.text.labelMedium?.copyWith(color: onSky),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              // The location opens Settings, where it can be updated.
            ],
          ),
          const SizedBox(height: AtharSpace.xxs),
          // AnimatedContainer(
          //   duration: const Duration(milliseconds: 900),
          //   curve: Curves.easeInOut,
          //   child: Row(
          //     children: [
          //       Flexible(
          //         child: Text(
          //           'home_today_summary'.trParams({
          //             'done': '$done',
          //             'total': '$total',
          //             'points': '${controller.pointsToday.value}',
          //           }),
          //           maxLines: 1,
          //           overflow: TextOverflow.ellipsis,
          //           style: context.text.bodySmall?.copyWith(
          //             color: onSky.withValues(alpha: 0.88),
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: AtharSpace.sm),
          //       Expanded(
          //         child: AtharProgressBar(
          //           value: total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0),
          //           height: 6,
          //           trackColor: onSky.withValues(alpha: 0.24),
          //           semanticsLabel: 'today'.tr,
          //           semanticsValue: '$done / $total',
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Today's prayers, as one grouped list
// ─────────────────────────────────────────────────────────────────────────
class _PrayerList extends GetView<HomeController> {
  const _PrayerList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.checklist;

      if (items.isEmpty) {
        return Column(
          children: [
            for (var i = 0; i < 5; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: AtharSpace.xs),
                child: AtharSkeleton(height: 60, radius: AtharRadius.card),
              ),
          ],
        );
      }

      return Material(
        color: context.athar.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtharRadius.card),
          side: BorderSide(color: context.colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _PrayerRow(item: items[i]),
              if (i < items.length - 1) const Divider(height: 1, indent: AtharSpace.md + 44 + AtharSpace.sm),
            ],
          ],
        ),
      );
    });
  }
}

/// What a prayer row says about its prayer — always as an icon and words, never
/// by colour alone.
enum _PrayerState {
  doneWithBonus(Icons.verified_rounded, 'performed_on_time'),
  doneLate(Icons.task_alt_rounded, 'performed_outside_time'),
  done(Icons.check_circle_rounded, 'prayer_state_done'),
  missed(Icons.history_rounded, 'missed_tap_to_log'),
  nowWithBonus(Icons.bolt_rounded, 'prayer_state_now'),
  now(Icons.radio_button_unchecked_rounded, 'prayer_state_now'),
  next(Icons.schedule_rounded, 'tour_home_next_title'),
  later(Icons.lock_clock_rounded, 'prayer_state_later');

  const _PrayerState(this.icon, this.labelKey);

  final IconData icon;
  final String labelKey;
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.item});

  final PrayerChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      // ── Source-of-truth booleans (do not duplicate this logic elsewhere) ──
      final busy = controller.marking.value == item.prayerName;
      final done = item.isCompleted;
      final active = controller.isActive(item.prayerName);
      final late = item.isLateCompleted;
      final hasStarted = item.time != null && !item.time!.isAfter(controller.now.value);
      final missed = !done && !active && hasStarted;
      final bonusLeft = (!done && active) ? controller.onTimeBonusRemaining(item.time) : null;
      final bonusEarned = done && item.onTimeBonusAwarded;
      final isNextUpcoming = !done && controller.nextPrayerKey.value == item.prayerName;

      final state = switch (true) {
        _ when done && bonusEarned => _PrayerState.doneWithBonus,
        _ when done && late => _PrayerState.doneLate,
        _ when done => _PrayerState.done,
        _ when missed => _PrayerState.missed,
        _ when active && bonusLeft != null => _PrayerState.nowWithBonus,
        _ when active => _PrayerState.now,
        _ when isNextUpcoming => _PrayerState.next,
        _ => _PrayerState.later,
      };

      final scheme = context.colors;
      final athar = context.athar;
      final visual = resolvePrayerVisualTheme(
        done: done,
        late: late,
        bonusEarned: bonusEarned,
        bonusAvailable: bonusLeft != null,
        missed: missed,
        active: active,
        isNextUpcoming: isNextUpcoming,
      );
      final accent = state == _PrayerState.later ? scheme.onSurfaceVariant : visual.accent(context);
      // Gold is for fills; as text on a light card it needs its deeper shade.
      final accentText =active && bonusLeft != null ? athar.goldText : scheme.onSurfaceVariant;
      final tappable = !done && (active || missed);
      final points = done ? item.pointsEarned : item.points;

      // The prayer whose time is in stands out most; the next one, with its
      // countdown, a step less.
      final tint = active && !done
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : state == _PrayerState.next
          ? scheme.primaryContainer.withValues(alpha: 0.28)
          : Colors.transparent;

      // final label = state == _PrayerState.next ? state.labelKey.trParams({'time': controller.countdown.value}) : state.labelKey.tr;
      final label =  state.labelKey.tr;

      return MergeSemantics(
        child: Material(
          color: tint,
          child: InkWell(
            onTap: tappable && !busy ? () => controller.mark(item,bonusLeft!=null) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.sm),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: busy
                          ? Padding(
                              padding: const EdgeInsets.all(AtharSpace.sm),
                              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                            )
                          : Icon(state.icon, size: AtharSize.iconLg, color: accent),
                    ),
                    const SizedBox(width: AtharSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.prayerName.tr, style: context.type.prayerName),
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(
                              color: state == _PrayerState.later ? scheme.onSurfaceVariant : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AtharSpace.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.time != null)
                          Text(
                            DateFormat('h:mm a', Get.locale?.languageCode).format(item.time!),
                            style: context.text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        const SizedBox(height: AtharSpace.xxs),
                        _PointsPill(points: points, bonusLeft: bonusLeft, color: accentText),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// The prayer's points; while the on-time bonus is open, also its countdown.
class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points, required this.bonusLeft, required this.color});

  final int points;
  final Duration? bonusLeft;
  final Color color;

  static String _mmss(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final left = bonusLeft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.xs, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AtharRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (left != null) ...[Icon(Icons.bolt_rounded, size: 14, color: color), const SizedBox(width: 2)],
          Text(
            left == null ? '+$points ${'point'.tr}' : 'bonus_pill'.trParams({'points': '${HomeController.onTimeBonusPoints}', 'time': _mmss(left)}),
            style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Today's practices: dhikr and the Quran, compact enough to sit on screen
// ─────────────────────────────────────────────────────────────────────────
class _Practices extends StatelessWidget {
  const _Practices();

  @override
  Widget build(BuildContext context) {
    final lastPage = Get.find<StorageProvider>().quranLastPageOrNull;

    return AtharGridGroup(
      // title: 'home_practices'.tr,
      children: [
        AtharGridTile(
          icon: Icons.all_inclusive_rounded,
          isStart: true,
          title: 'dhikr_home_card_title'.tr,
          subtitle: 'dhikr_home_card_sub'.tr,
          onTap: () => Get.to(() => const DhikrView(), binding: DhikrBinding()),
        ),
        AtharGridTile(
          icon: Icons.menu_book_rounded,
          title: 'quran_home_card_title'.tr,
          subtitle: 'quran_home_card_sub'.tr,
          onTap: () => Get.to(() => const QuranView(), binding: QuranBinding()),
        ),
      ],
    );
  }
}
