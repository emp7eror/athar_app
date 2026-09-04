import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'animated_counter.dart';
import 'dhikr_controller.dart';
import 'misbaha_widget.dart';

/// Dark emerald and gold, used only on this page. The rest of the app keeps its
/// own light/dark themes; the misbaha is deliberately its own quiet room.
class _Palette {
  static const bgTop = Color(0xFF06231A);
  static const bgBottom = Color(0xFF010B08);
  static const gold = Color(0xFFC8A95B);
  static const goldBright = Color(0xFFEBD9A3);
  static const emeraldLine = Color(0xFF18543E);
  static const textFaint = Color(0xFF7C9A8C);
}

class DhikrView extends GetView<DhikrController> {
  const DhikrView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bgBottom,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _Palette.goldBright,
        title: Text(
          'dhikr_title'.tr,
          style: const TextStyle(color: _Palette.goldBright, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            // The virtue lives behind an icon rather than on the page, so the
            // counter and the strand keep the screen to themselves.
            onPressed: () => _showVirtue(context),
            tooltip: 'dhikr_virtue_title'.tr,
            icon: const Icon(Icons.auto_stories_outlined, color: _Palette.gold),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.1,
            colors: [_Palette.bgTop, _Palette.bgBottom],
          ),
        ),
        child: Obx(() {
          if (controller.loading.value) {
            return const Center(
              child: CircularProgressIndicator(color: _Palette.gold),
            );
          }
          if (controller.failed.value) {
            return _ErrorState(onRetry: controller.load);
          }
          return const _DhikrBody();
        }),
      ),
    );
  }
}

void _showVirtue(BuildContext context) {
  final key = Get.find<DhikrController>().selected.value;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _Palette.bgTop,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => SafeArea(
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
                  color: _Palette.emeraldLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'dhikr_virtue_title'.tr,
              style: const TextStyle(
                color: _Palette.gold,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'dhikr_virtue_$key'.tr,
              style: const TextStyle(color: Colors.white, height: 1.8, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              'dhikr_virtue_source_$key'.tr,
              style: const TextStyle(
                color: _Palette.textFaint,
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
          const _DhikrSelector(),
          const SizedBox(height: 10),
          const _DhikrPhrase(),

          // The counter takes the middle; the strand owns the bottom third so
          // it falls under the thumb.
          // scaleDown keeps the dial whole on short screens rather than
          // letting it overflow the space the strand needs.
          const Expanded(
            flex: 5,
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: _CounterDial()),
            ),
          ),
          const Expanded(flex: 4, child: _MisbahaZone()),
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
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _Palette.emeraldLine),
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
                        color: active ? _Palette.gold.withValues(alpha: 0.16) : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: active ? _Palette.gold.withValues(alpha: 0.55) : Colors.transparent,
                        ),
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
                                color: active ? _Palette.goldBright : _Palette.textFaint,
                              ),
                            ),
                          ),
                          if (done) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.check_circle_rounded, size: 14, color: _Palette.gold),
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
            style: const TextStyle(
              color: _Palette.goldBright,
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
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(color: _Palette.emeraldLine, width: 1),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation(
                        rewarded ? _Palette.goldBright : _Palette.gold,
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
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'dhikr_of_target'.trParams({'target': '${controller.target.value}'}),
                      style: const TextStyle(color: _Palette.textFaint, fontSize: 12.5),
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
                    color: _Palette.goldBright,
                  )
                : _Caption(
                    key: const ValueKey('remaining'),
                    icon: Icons.flag_outlined,
                    text: 'dhikr_remaining'.trParams({
                      'count': '$remaining',
                      'points': '${controller.rewardPoints.value}',
                    }),
                    color: _Palette.textFaint,
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

      return Stack(
        children: [
          Positioned.fill(
            child: MisbahaStrand(
              count: controller.countOf(controller.selected.value),
              enabled: !paused,
              onTap: controller.tap,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: paused ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _Palette.emeraldLine),
                  ),
                  child: Text(
                    'dhikr_paused'.tr,
                    style: const TextStyle(color: _Palette.gold, fontSize: 12, fontWeight: FontWeight.w600),
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
            const Icon(Icons.cloud_off_rounded, size: 44, color: _Palette.textFaint),
            const SizedBox(height: 12),
            Text(
              'dhikr_load_failed'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Palette.textFaint, height: 1.6),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _Palette.gold,
                foregroundColor: const Color(0xFF06231A),
              ),
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
