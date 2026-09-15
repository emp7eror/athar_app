import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/prayer_log_model.dart';
import '../../widgets/framed_avatar.dart';
import '../dhikr/dhikr_binding.dart';
import '../dhikr/dhikr_view.dart';
import '../quran/quran_binding.dart';
import '../quran/quran_view.dart';
import '../shell/shell_view.dart';
import 'home_controller.dart';
import 'prayer_sky_theme.dart';
import 'prayer_visual_theme.dart';
import '../../core/tour/tour_widgets.dart';
import '../tour/app_tours.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AI coach button sits on the shell's nav bar, on every tab.
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            // Clear of the floating nav bar and the AI button raised on it.
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
            // Keeps the whole page built so tour steps can scroll to any card.
            scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
            children: [

              // ── الهيدر: صورة + اسم + أيقونة الإعدادات ──
              Row(
                children: [
                  // الصورة والاسم → ينقل لصفحة الملف الشخصي
                  TourTarget(
                    id: TourTargets.homeProfile,
                    child: GestureDetector(
                    onTap: () => Get.find<ShellController>().index.value = 4,
                    child: Obx(() {
                      final name      = controller.userName.value;
                      final avatarUrl = controller.avatarUrl.value;
                      return Row(children: [
                        FramedAvatar(
                          name: name,
                          avatarUrl: avatarUrl,
                          frameAsset: controller.level.value?.frame,
                          level: controller.level.value?.level,
                          radius: 13,
                          backgroundColor: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMuted)),

                              Text( controller.level.value!.name,
                                  style: TextStyle(color: context.athar.textMuted, fontSize: 12)),

                          ],
                        ), const SizedBox(width: 10),

                      ]);
                    }),
                  ),
                  ),
                  const Spacer(),
                  // Replays this page's product tour.
                  const TourHelpButton(pageId: TourPages.home),
                  const SizedBox(width: 10),
                  // أيقونة الإعدادات → ينقل لصفحة الإعدادات
                  TourTarget(
                    id: TourTargets.homeSettings,
                    child: _CircleIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => Get.find<ShellController>().index.value = 5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                  )
                ],
              ),

              // const SizedBox(height: 10),
              // Obx(() => LevelProgressCard(level: controller.level.value)),
              const SizedBox(height: 10),
              const TourTarget(id: TourTargets.homeNextPrayer, child: _NextPrayerCard()),
              const SizedBox(height: 15),
              _SectionHeader('today'.tr),
              const SizedBox(height: 12),
              TourTarget(
                id: TourTargets.homePrayers,
                child: Obx(() => Column(
                children: controller.checklist
                    .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _PrayerTile(item: item),
                ))
                    .toList(),
              )),
              ),
              // const _QuoteCard(),
              const SizedBox(height: 12),
              // Dhikr + Quran side by side, equal height.
              TourTarget(
                id: TourTargets.homePractices,
                child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _HomeGridCard(
                        icon: Icons.brightness_7_rounded,
                        title: 'dhikr_home_card_title'.tr,
                        subtitle: 'dhikr_home_card_sub'.tr,
                        colors: const [Color(0xFF243329), Color(0xFF15201A)],
                        onTap: () => Get.to(() => const DhikrView(), binding: DhikrBinding()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HomeGridCard(
                        icon: Icons.menu_book_rounded,
                        title: 'quran_home_card_title'.tr,
                        subtitle: 'quran_home_card_sub'.tr,
                        colors: const [Color(0xFF243329), Color(0xFF15201A)],
                        onTap: () => Get.to(() => const QuranView(), binding: QuranBinding()),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Half-width entry card (tasbeeh / Quran Werd) for the Home grid, matching
/// the beige section styling used elsewhere on Home.
class _HomeGridCard extends StatelessWidget {
  const _HomeGridCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
  });

  /// Background gradient behind the text.
  final List<Color> colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = context.athar.gold;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 132),
            child: Stack(
              children: [
                // Large faded watermark instead of an icon badge.
                PositionedDirectional(
                  end: -18,
                  bottom: -18,
                  child: Icon(icon, size: 110, color: Colors.white.withValues(alpha: 0.08)),
                ),
                // Soft gold glow in the top corner.
                PositionedDirectional(
                  top: -40,
                  start: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [gold.withValues(alpha: 0.22), gold.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Container(
                      //   width: 22,
                      //   height: 3,
                      //   decoration: BoxDecoration(
                      //     color: gold,
                      //     borderRadius: BorderRadius.circular(2),
                      //   ),
                      // ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.5,
                        ),
                      ),
                    ],
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.athar.card,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: context.colors.primary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Hero: next-prayer countdown
// ─────────────────────────────────────────────────────────────────────────
class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      // The card takes on the sky of the prayer it's counting down to.
      final sky = PrayerSkyTheme.of(controller.nextPrayerKey.value);

      return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: sky.colors.length == 2 ? [...sky.colors, sky.colors.last] : sky.colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: sky.colors.last.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
        children: [
          // Stars (dawn, sunset, night).
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: SkyStarsPainter(count: sky.stars)),
            ),
          ),
          // Light source glow behind the watermark.
          PositionedDirectional(
            end: -50,
            bottom: -60,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [sky.glow.withValues(alpha: 0.35), sky.glow.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          // Sun / moon / twilight watermark.
          PositionedDirectional(
            end: -20,
            bottom: -28,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Icon(
                  sky.watermark,
                  key: ValueKey(sky.watermark),
                  size: 130,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mosque_outlined, size: 18, color: sky.accent),
                      const SizedBox(width: 6),
                      Text('next_prayer'.tr, style: context.text.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                  // Tapping the location opens Settings to change it — the
                  // hero card's own update-location button was removed.
                  InkWell(
                    onTap: () => Get.find<ShellController>().index.value = 5,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Obx(() => Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 15, color: Colors.white.withValues(alpha: 0.85)),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 96),
                            child: Text(
                              controller.locationLabel.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ),
                        ],
                      )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Obx(
                    () => Text(
                      controller.nextPrayerKey.value.isEmpty ? '—' : controller.nextPrayerKey.value.tr,
                      style: context.text.headlineMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  Obx(
                        () => Text(
                      controller.countdown.value,
                      style: context.text.displayMedium?.copyWith(
                        color: sky.accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // const _DailyProgressBar(),
            ],
          ),
          ),
        ],
        ),
      ),
    );
    });
  }
}

class _DailyProgressBar extends StatelessWidget {
  const _DailyProgressBar();

  static const _maxPoints = 180;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final athar = context.athar;

    return Obx(() {
      final pts = controller.pointsToday.value;
      final value = (pts / _maxPoints).clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('daily_progress'.tr, style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
              Text('$pts / $_maxPoints', style: context.text.labelLarge?.copyWith(color: athar.gold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(athar.gold),
            ),
          ),
        ],
      );
    });
  }
}


// ─────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: context.athar.gold, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: context.text.titleLarge),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Prayer / daily-impact tile
// ─────────────────────────────────────────────────────────────────────────
class _PrayerTile extends StatelessWidget {
  const _PrayerTile({required this.item});

  final PrayerChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final athar = context.athar;

    return Obx(() {
      // ── Source-of-truth booleans (do not duplicate this logic elsewhere) ──
      final busy   = controller.marking.value == item.prayerName;
      final done   = item.isCompleted;
      final active = controller.isActive(item.prayerName);
      final late   = item.isLateCompleted;
      final hasStarted =
          item.time != null && !item.time!.isAfter(controller.now.value);
      final missed = !done && !active && hasStarted;
      final bonusLeft = (!done && active)
          ? controller.onTimeBonusRemaining(item.time)
          : null;
      final bonusEarned = done && item.onTimeBonusAwarded;
      final isNextUpcoming =
          !done && controller.nextPrayerKey.value == item.prayerName;
      // ── Resolve the single visual theme that drives every element ──
      final theme = resolvePrayerVisualTheme(
        done: done,
        late: late,
        bonusEarned: bonusEarned,
        bonusAvailable: bonusLeft != null,
        missed: missed,
        active: active,
        isNextUpcoming: isNextUpcoming,
      );
      final accent = theme.accent(context);
      final displayPoints = done ? item.pointsEarned : item.points;

      // Row tint — neutral (distant future) tiles keep the default card look.
      final borderColor = AppColors.primary.withValues(alpha: 0.45);
      final bgColor = athar.card;

      // Text color for name/time — themed when the tile is colored, otherwise
      // fall back to the body default so distant-future tiles stay readable.
      // final Color? textColor = theme.tintsRow ? accent : null;
      // final timeColor = theme.tintsRow ? athar.success : athar.textMuted;

      // The "current" prayer — the one that's in its active window OR the
      // next up when none is active — earns a thicker, saturated border so
      // the actionable row pops without relying on color alone.
      final isCurrent = active;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? ( (bonusLeft!=null) ?accent: AppColors.primary.withValues(alpha: 0.9)) : borderColor,
            width: isCurrent ? 2.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // ── حالة الصلاة (action button/icon) ──
            _TrailingState(
              busy: busy,
              late: late,
              done: done,
              active: active,
              missed: missed,
              accent: accent,
              item: item,
            ),
            const SizedBox(width: 12),

            // ── اسم الصلاة (+ label for late / missed sub-state) ──
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.prayerName.tr,
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  if (late) ...[
                    const SizedBox(height: 2),
                    Text(
                      'performed_outside_time'.tr,
                      style: context.text.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else if (missed) ...[
                    const SizedBox(height: 2),
                    Text(
                      'missed_tap_to_log'.tr,
                      style: context.text.labelSmall?.copyWith(
                        color: accent,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (bonusEarned) ...[
                    const SizedBox(height: 2),
                    Text(
                      'performed_on_time'.tr,
                      style: context.text.labelSmall?.copyWith(
                        color: accent,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                ],
              ),
            ),

            // ── الوقت ──
            if (item.time != null)
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('h:mm a', Get.locale?.languageCode).format(item.time!),
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

            // ── النقاط ──
            // Single points badge — value comes from `pointsEarned` once the
            // server has credited it (base until then). Color follows the
            // same [theme] as the row so everything moves together.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bonusLeft != null) ...[
                    Icon(Icons.bolt_rounded, size: 18, color: accent),
                    const SizedBox(width: 4),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+$displayPoints   ${'point'.tr}',
                        style: context.text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      if (bonusLeft != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'bonus_pill'.trParams({
                            'points': '${HomeController.onTimeBonusPoints}',
                            'time': _mmss(bonusLeft),
                          }),
                          style: context.text.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _mmss(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
          '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}


class _TrailingState extends StatelessWidget {
  const _TrailingState({
    required this.busy,
    required this.late,
    required this.done,
    required this.active,
    required this.missed,
    required this.accent,
    required this.item,
  });

  final bool busy;
  final bool late;
  final bool done;
  final bool active;
  final bool missed;
  final Color accent; // resolved by PrayerVisualTheme — drives every icon hue
  final PrayerChecklistItem item;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: accent),
      );
    }
     if (done) {
      // Completed check inherits the accent so on-time (green) vs bonus (gold)
      // vs Qada (orange) is signalled by the very same icon color.
      return Icon(Icons.check_circle_rounded, color: accent, size: 30);
    }
    final controller = Get.find<HomeController>();

    // Both "active" and "missed" prayers are tappable — active opens the
    // normal confirm dialog, missed opens the missed-prayer dialog. Truly
    // future prayers fall through to the disabled lock (kept muted so the
    // themed rows next to it read as the actionable ones).
    if (active) {
      // Bonus preview surfaces a sparkle instead of the plain circle so the
      // "act now to earn +10" affordance is unmistakable — accent is already
      // gold in that case per the resolver.
      // final bonusPreview = controller.onTimeBonusRemaining(item.time) != null;
      return GestureDetector(
        onTap: () => controller.mark(item),
        child: Icon(
           Icons.radio_button_unchecked,
          color: accent,
          size: 30,
        ),
      );
    }
    if (missed) {
      return GestureDetector(
        onTap: () => controller.mark(item),
        child: Icon(Icons.history_toggle_off_rounded, color: accent, size: 30),
      );
    }
    return Icon(Icons.lock_outline_rounded,
        color: context.athar.primaryDark, size: 30);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Quote / reflection card
// ─────────────────────────────────────────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      if (controller.quote.value.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 8),
        // Extra room on the physical right so the floating coach button never
        // covers the text — this card sits at the bottom of the scroll, right
        // where the FAB floats.
        padding: const EdgeInsets.fromLTRB(10, 10, 64, 10),
        decoration: BoxDecoration(color: context.athar.beige, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote_rounded, color: context.athar.gold, size: 28),
            const SizedBox(height: 8),
            Text(controller.quote.value, style: context.text.bodyLarge?.copyWith(height: 1.6)),
            if (controller.quoteSource.value.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '— ${controller.quoteSource.value}',
                style: context.text.bodySmall?.copyWith(color: context.athar.textMuted, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      );
    });
  }
}
