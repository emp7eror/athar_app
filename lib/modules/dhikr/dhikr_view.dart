import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'animated_counter.dart';
import 'dhikr_controller.dart';
import 'misbaha_widget.dart';
import '../../core/tour/tour_widgets.dart';
import '../tour/app_tours.dart';

class DhikrView extends GetView<DhikrController> {
  const DhikrView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dhikr_title'.tr),
        actions: [
          const TourHelpButton(pageId: TourPages.dhikr, style: TourHelpStyle.appBar),
          // Shake to count — on/off, remembered on the device.
          TourTarget(
            id: TourTargets.dhikrShake,
            child: Obx(() {
              final on = controller.shakeEnabled.value;
              return IconButton(
                onPressed: controller.toggleShake,
                isSelected: on,
                tooltip: on ? 'dhikr_shake_on'.tr : 'dhikr_shake_off'.tr,
                icon: const Icon(Icons.vibration_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: on ? context.athar.gold : null,
                  backgroundColor: on ? context.athar.gold.withValues(alpha: 0.16) : null,
                ),
              );
            }),
          ),
          TourTarget(
            id: TourTargets.dhikrVirtue,
            child: IconButton(
              // The virtue lives behind an icon rather than on the page, so the
              // counter and the strand keep the screen to themselves.
              onPressed: () => _showVirtue(context),
              tooltip: 'dhikr_virtue_title'.tr,
              icon: const Icon(Icons.auto_stories_outlined),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) => Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.failed.value) {
            return _ErrorState(onRetry: controller.load);
          }
          // The tour starts once the counters have loaded.
          return const TourAutoStart(pageId: TourPages.dhikr, child: _DhikrBody());
        }),
      ),
    );
  }
}

void _showVirtue(BuildContext context) {
  final key = Get.find<DhikrController>().selected.value;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.athar.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'dhikr_virtue_title'.tr,
              style: TextStyle(
                color: context.athar.gold,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'dhikr_virtue_$key'.tr,
              style: context.text.bodyMedium?.copyWith(height: 1.8, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              'dhikr_virtue_source_$key'.tr,
              style: TextStyle(
                color: context.athar.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DhikrBody extends StatelessWidget {
  const _DhikrBody();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const TourTarget(id: TourTargets.dhikrSelector, child: _DhikrSelector()),
          const SizedBox(height: 10),
          const _DhikrPhrase(),

          // The counter takes the middle; the strand owns the bottom third so
          // it falls under the thumb.
          // scaleDown keeps the dial whole on short screens rather than
          // letting it overflow the space the strand needs.
          const Expanded(
            flex: 5,
            child: Center(
              // Target the FittedBox (not the dial inside it) so the spotlight
              // matches the dial's scaled, on-screen size.
              child: TourTarget(
                id: TourTargets.dhikrCounter,
                child: FittedBox(fit: BoxFit.scaleDown, child: _CounterDial()),
              ),
            ),
          ),
          const Expanded(
            flex: 4,
            child: TourTarget(id: TourTargets.dhikrBeads, child: _MisbahaZone()),
          ),
        ],
      ),
    );
  }
}

/// Switches between the two adhkar.
class _DhikrSelector extends StatelessWidget {
  const _DhikrSelector();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DhikrController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Obx(() => Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.athar.beige,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: DhikrController.keys.map((key) {
                final active = controller.selected.value == key;
                final done = controller.isRewarded(key);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.select(key),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'dhikr_${key}_short'.tr,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: active ? Colors.white : context.athar.textMuted,
                              ),
                            ),
                          ),
                          if (done) ...[
                            const SizedBox(width: 5),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: active ? Colors.white : context.athar.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )),
    );
  }
}

class _DhikrPhrase extends StatelessWidget {
  const _DhikrPhrase();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DhikrController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
      child: Obx(() => Text(
            'dhikr_${controller.selected.value}'.tr,
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(
              fontSize: 21,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          )),
    );
  }
}

/// The circular tally at the centre of the screen.
class _CounterDial extends StatelessWidget {
  const _CounterDial();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DhikrController>();

    return Obx(() {
      final key = controller.selected.value;
      final count = controller.countOf(key);
      final progress = controller.progressOf(key);
      final remaining = controller.remainingOf(key);
      final rewarded = controller.isRewarded(key);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 186,
            height: 186,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft inner disc so the number never floats on the gradient.
                Container(
                  width: 158,
                  height: 158,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.athar.beige.withValues(alpha: 0.45),
                    border: Border.all(color: context.athar.beige, width: 1.5),
                  ),
                ),

                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: context.athar.beige,
                      valueColor: AlwaysStoppedAnimation(
                        rewarded ? context.athar.gold : AppColors.primary,
                      ),
                    ),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCounter(
                      value: count,
                      style: const TextStyle(
                        fontSize: 54,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'dhikr_of_target'.trParams({'target': '${controller.target.value}'}),
                      style: context.text.bodySmall?.copyWith(color: context.athar.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: rewarded
                ? _Caption(
                    key: const ValueKey('done'),
                    icon: Icons.verified_rounded,
                    text: 'dhikr_reward_done'.tr,
                    color: context.athar.gold,
                  )
                : _Caption(
                    key: const ValueKey('remaining'),
                    icon: Icons.flag_outlined,
                    text: 'dhikr_remaining'.trParams({
                      'count': '$remaining',
                      'points': '${controller.rewardPoints.value}',
                    }),
                    color: context.athar.textMuted,
                  ),
          ),
        ],
      );
    });
  }
}

class _Caption extends StatelessWidget {
  const _Caption({super.key, required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// The strand plus the cooldown notice, filling the bottom of the screen.
class _MisbahaZone extends StatelessWidget {
  const _MisbahaZone();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DhikrController>();

    return Obx(() {
      final paused = controller.cooldown.value;
      final shaking = controller.shakeEnabled.value;

      return Stack(
        children: [
          Positioned.fill(
            child: MisbahaStrand(
              count: controller.countOf(controller.selected.value),
              enabled: !paused,
              onTap: controller.tap,
              strike: controller.shakeStrikes.value,
            ),
          ),
          // One notice slot: the cooldown message wins; otherwise, with shake
          // counting on, a reminder that shaking counts.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: paused || shaking ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.athar.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: !paused && shaking
                          ? context.athar.gold.withValues(alpha: 0.5)
                          : context.athar.beige,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!paused && shaking) ...[
                        Icon(Icons.vibration_rounded, size: 14, color: context.athar.gold),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        paused ? 'dhikr_paused'.tr : 'dhikr_shake_hint'.tr,
                        style: TextStyle(color: context.athar.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: context.athar.textMuted),
            const SizedBox(height: 12),
            Text(
              'dhikr_load_failed'.tr,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: context.athar.textMuted, height: 1.6),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text('retry'.tr)),
          ],
        ),
      ),
    );
  }
}
