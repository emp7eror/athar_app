import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../tour/app_tours.dart';
import 'animated_counter.dart';
import 'dhikr_controller.dart';
import 'misbaha_widget.dart';

/// Dhikr: the phrase, the count, and the strand under your thumb.
class DhikrView extends GetView<DhikrController> {
  const DhikrView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AtharAppBar(
        title: 'dhikr_title'.tr,
        actions: [
          const TourHelpButton(pageId: TourPages.dhikr, style: TourHelpStyle.appBar),
          // Shake to count — on/off, remembered on the device.
          TourTarget(
            id: TourTargets.dhikrShake,
            child: Obx(() {
              final on = controller.shakeEnabled.value;
              return AtharIconButton(
                icon: Icons.vibration_rounded,
                tooltip: on ? 'dhikr_shake_on'.tr : 'dhikr_shake_off'.tr,
                variant: on ? AtharIconButtonVariant.tonal : AtharIconButtonVariant.plain,
                color: on ? context.athar.goldText : null,
                onPressed: controller.toggleShake,
              );
            }),
          ),
          TourTarget(
            id: TourTargets.dhikrVirtue,
            child: AtharIconButton(
              // The virtue lives behind an icon rather than on the page, so the
              // counter and the strand keep the screen to themselves.
              icon: Icons.auto_stories_rounded,
              tooltip: 'dhikr_virtue_title'.tr,
              onPressed: () => _showVirtue(context),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) => Obx(() {
          if (controller.loading.value) {
            return const AtharLoadingState();
          }
          if (controller.failed.value) {
            return AtharErrorState(message: 'dhikr_load_failed'.tr, onRetry: controller.load);
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

  showAtharSheet<void>(
    context: context,
    scrollControlled: false,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AtharSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtharSheetHeader(title: 'dhikr_virtue_title'.tr),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'dhikr_virtue_$key'.tr,
                    style: context.text.bodyLarge?.copyWith(height: 1.9),
                  ),
                  const SizedBox(height: AtharSpace.sm),
                  Text('dhikr_virtue_source_$key'.tr, style: context.type.caption),
                ],
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
          const SizedBox(height: AtharSpace.xs),
          const TourTarget(id: TourTargets.dhikrSelector, child: _DhikrSelector()),
          const _DhikrPhrase(),
          // The counter takes the middle; the strand owns the bottom third so
          // it falls under the thumb. scaleDown keeps the dial whole on short
          // screens rather than letting it overflow the space the strand needs.
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

/// Switches between the two adhkar, marking the one whose daily reward is in.
class _DhikrSelector extends StatelessWidget {
  const _DhikrSelector();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DhikrController>();
    final scheme = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg),
      child: Obx(
        () => Container(
          padding: const EdgeInsets.all(AtharSpace.xxs),
          decoration: BoxDecoration(
            color: context.athar.beige,
            borderRadius: BorderRadius.circular(AtharRadius.pill),
          ),
          child: Row(
            children: DhikrController.keys.map((key) {
              final active = controller.selected.value == key;
              final done = controller.isRewarded(key);

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: active,
                  inMutuallyExclusiveGroup: true,
                  child: AnimatedContainer(
                    duration: AtharMotion.base,
                    curve: AtharMotion.standard,
                    decoration: BoxDecoration(
                      color: active ? scheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AtharRadius.pill),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => controller.select(key),
                        customBorder: const StadiumBorder(),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'dhikr_${key}_short'.tr,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.labelLarge?.copyWith(
                                    color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (done) ...[
                                const SizedBox(width: AtharSpace.xxs + 1),
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: AtharSize.iconSm,
                                  color: active ? scheme.onPrimary : context.athar.success,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _DhikrPhrase extends StatelessWidget {
  const _DhikrPhrase();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DhikrController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.md, AtharSpace.lg, 0),
      child: Obx(
        () => Text(
          'dhikr_${controller.selected.value}'.tr,
          textAlign: TextAlign.center,
          style: context.text.titleLarge?.copyWith(height: 1.8),
        ),
      ),
    );
  }
}

/// The circular tally at the centre of the screen.
class _CounterDial extends StatelessWidget {
  const _CounterDial();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DhikrController>();
    final athar = context.athar;
    final scheme = context.colors;

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
                // Soft inner disc so the number never floats on the ground.
                Container(
                  width: 158,
                  height: 158,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: athar.beige.withValues(alpha: 0.45),
                    border: Border.all(color: athar.beige, width: 1.5),
                  ),
                ),
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: AtharMotion.emphasis,
                    curve: AtharMotion.standard,
                    builder: (context, value, child) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: athar.beige,
                      valueColor: AlwaysStoppedAnimation(rewarded ? scheme.primary : scheme.primary),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCounter(
                      value: count,
                      style: context.type.bigNumber.copyWith(
                        fontSize: 54,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: AtharSpace.xxs + 2),
                    Text(
                      'dhikr_of_target'.trParams({'target': '${controller.target.value}'}),
                      style: context.type.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AtharSpace.md),
          AnimatedSwitcher(
            duration: AtharMotion.slow,
            child: rewarded
                ? _Caption(
                    key: const ValueKey('done'),
                    icon: Icons.verified_rounded,
                    text: 'dhikr_reward_done'.tr,
                    color: athar.textMuted,
                  )
                : _Caption(
                    key: const ValueKey('remaining'),
                    icon: Icons.flag_rounded,
                    text: 'dhikr_remaining'.trParams({
                      'count': '$remaining',
                      'points': '${controller.rewardPoints.value}',
                    }),
                    color: scheme.onSurfaceVariant,
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
        Icon(icon, size: AtharSize.iconSm, color: color),
        const SizedBox(width: AtharSpace.xs),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// The strand plus the one notice slot, filling the bottom of the screen.
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
              // motion: controller.shakeStrikes.value,
            ),
          ),
          // The cooldown message wins; otherwise, with shake counting on, a
          // reminder that shaking counts.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: paused || shaking ? 1 : 0,
              duration: AtharMotion.base,
              child: Center(
                child: AtharBadge(
                  label: paused ? 'dhikr_paused'.tr : 'dhikr_shake_hint'.tr,
                  icon: !paused && shaking ? Icons.vibration_rounded : null,
                  tone: !paused && shaking ? AtharTone.gold : AtharTone.neutral,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
