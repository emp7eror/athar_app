import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/prayer_log_model.dart';
import '../shell/shell_view.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [

              // ── الهيدر: صورة + اسم + أيقونة الإعدادات ──
              Row(
                children: [
                  // الصورة والاسم → ينقل لصفحة الملف الشخصي
                  GestureDetector(
                    onTap: () => Get.find<ShellController>().index.value = 4,
                    child: Obx(() {
                      final name      = controller.userName.value;
                      final avatarUrl = controller.avatarUrl.value;
                      return Row(children: [
                        avatarUrl.isNotEmpty
                            ? CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(avatarUrl),
                            backgroundColor: AppColors.primary)
                            : CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            )),
                        const SizedBox(width: 10),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                      ]);
                    }),
                  ),
                  const Spacer(),
                  // أيقونة الإعدادات → ينقل لصفحة الإعدادات
                  _CircleIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () => Get.find<ShellController>().index.value = 5,
                  ),
                  const SizedBox(width: 10),
                  _CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                  )
                ],
              ),

              const SizedBox(height: 10),
              const _LocationChip(),
              const SizedBox(height: 10),
              const _NextPrayerCard(),
              const SizedBox(height: 15),
              _SectionHeader('today'.tr),
              const SizedBox(height: 12),
              Obx(() => Column(
                children: controller.checklist
                    .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _PrayerTile(item: item),
                ))
                    .toList(),
              )),
              const _QuoteCard(),
            ],
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
// Location chip
// ─────────────────────────────────────────────────────────────────────────
class _LocationChip extends StatelessWidget {
  const _LocationChip();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: context.athar.beige, borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 18, color: context.colors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(controller.locationLabel.value, style: context.text.bodySmall, overflow: TextOverflow.ellipsis),
            ),
            if (controller.updatingLocation.value)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else
              InkWell(
                onTap: controller.updateLocation,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.my_location, size: 16, color: context.colors.primary),
                      const SizedBox(width: 4),
                      Text('update_location'.tr, style: context.text.labelSmall?.copyWith(color: context.colors.primary)),
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
// Hero: next-prayer countdown
// ─────────────────────────────────────────────────────────────────────────
class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final athar = context.athar;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: athar.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: context.colors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative ripple rings echoing the brand moodboard.
          Positioned(top: -60, right: -40, child: _RippleRings(color: Colors.white.withValues(alpha: 0.06))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.mosque_outlined, size: 18, color: athar.gold),
                  const SizedBox(width: 6),
                  Text('next_prayer'.tr, style: context.text.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
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
                        color: athar.gold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              const _DailyProgressBar(),
            ],
          ),
        ],
      ),
    );
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

class _RippleRings extends StatelessWidget {
  const _RippleRings({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final size in const [160.0, 120.0, 80.0])
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
            ),
        ],
      ),
    );
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
      final busy = controller.marking.value == item.prayerName;
      final done = item.isCompleted;
      final active = controller.isActive(item.prayerName);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),  // ← أقل
        decoration: BoxDecoration(
          color: done ? athar.sage.withValues(alpha: 0.22) : athar.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: done ? athar.success.withValues(alpha: 0.4) : context.colors.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _TrailingState(busy: busy, done: done, active: active, item: item),
                SizedBox(width: 50,),
                Text(
                  '${item.prayerName.tr}',
                  style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),


            Text(
              '+${item.points}  ${'point'.tr}',
              style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );    });
  }
}

class _TrailingState extends StatelessWidget {
  const _TrailingState({required this.busy, required this.done, required this.active, required this.item});

  final bool busy;
  final bool done;
  final bool active;
  final PrayerChecklistItem item;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (done) {
      return Icon(Icons.check_circle_rounded, color: context.athar.success, size: 30);
    }
    final controller = Get.find<HomeController>();
    return GestureDetector(
      onTap: active ? () => controller.mark(item) : null,
      child: Icon(
        active ? Icons.radio_button_unchecked : Icons.lock_outline_rounded,
        color: active ? context.colors.primary : context.athar.textMuted,
        size: 30,
      ),
    );
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
        padding: const EdgeInsets.all(10),
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
