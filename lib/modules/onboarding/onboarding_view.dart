import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import 'onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientRipples()),
          SafeArea(
            child: Column(
              children: [
                const _TopControls(),
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: OnboardingController.pages.length,
                    itemBuilder: (context, index) {
                      final page = OnboardingController.pages[index];
                      return _AnimatedPage(
                        controller: controller.pageController,
                        index: index,
                        child: OnboardingCard(page: page),
                      );
                    },
                  ),
                ),
                const _BottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Top bar: language toggle + Skip (auto-flips with text direction)
// ─────────────────────────────────────────────────────────────────────────
class _TopControls extends StatelessWidget {
  const _TopControls();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: Get.find<LocalizationController>().toggle,
                icon: Icon(Icons.language_outlined, size: 18, color: context.colors.primary),
                label: Text(
                  'AR / EN',
                  style: context.text.labelLarge?.copyWith(color: context.colors.primary),
                ),
              ),
              IconButton(
                onPressed: Get.find<ThemeController>().toggle,
                icon: Icon(
                  Get.find<ThemeController>().isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 20,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          Obx(() => AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: controller.isLast ? 0 : 1,
                child: TextButton(
                  onPressed: controller.isLast ? null : controller.skip,
                  child: Text(
                    'skip'.tr,
                    style: context.text.labelLarge?.copyWith(color: context.athar.textMuted),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Parallax + fade wrapper for each page
// ─────────────────────────────────────────────────────────────────────────
class _AnimatedPage extends StatelessWidget {
  const _AnimatedPage({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        double delta = 0;
        if (controller.position.haveDimensions) {
          delta = (controller.page ?? controller.initialPage.toDouble()) - index;
        }
        final t = delta.abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - t * 0.6,
          child: Transform.translate(
            offset: Offset(0, t * 40),
            child: Transform.scale(scale: 1 - t * 0.06, child: child),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Single page content: motif emblem + title + subtitle
// ─────────────────────────────────────────────────────────────────────────
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key, required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MotifEmblem(motif: page.motif),
          const SizedBox(height: 48),
          Text(
            page.titleKey.tr,
            textAlign: TextAlign.center,
            style: context.text.headlineMedium?.copyWith(
              color: context.colors.primary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitleKey.tr,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.athar.textMuted,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Circular emblem hosting the per-screen motif
// ─────────────────────────────────────────────────────────────────────────
class _MotifEmblem extends StatelessWidget {
  const _MotifEmblem({required this.motif});

  final OnboardingMotif motif;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo rings behind the emblem.
          for (final d in const [220.0, 176.0])
            Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.primary.withValues(alpha: d == 220 ? 0.04 : 0.06),
              ),
            ),
          // Beige core disc.
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: context.athar.beige,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _MotifGraphic(motif: motif),
          ),
        ],
      ),
    );
  }
}

class _MotifGraphic extends StatelessWidget {
  const _MotifGraphic({required this.motif});

  final OnboardingMotif motif;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    final gold = context.athar.gold;

    switch (motif) {
      case OnboardingMotif.ripple:
        return CustomPaint(size: const Size(96, 96), painter: _RipplePainter(primary, gold));
      case OnboardingMotif.streak:
        return CustomPaint(size: const Size(96, 96), painter: _StreakPainter(primary, gold));
      case OnboardingMotif.heart:
        return Icon(Icons.favorite_rounded, size: 64, color: primary);
      case OnboardingMotif.journal:
        return Icon(Icons.auto_stories_rounded, size: 64, color: primary);
      case OnboardingMotif.logo:
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(
              'app_name'.tr,
              style: context.text.displayLarge?.copyWith(color: primary, fontSize: 56),
            ),
            Positioned(top: -2, right: -6, child: Icon(Icons.auto_awesome, size: 22, color: gold)),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bottom: page indicator + primary CTA
// ─────────────────────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  const _BottomControls();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        children: [
          Obx(() => PageIndicator(
                count: OnboardingController.pages.length,
                activeIndex: controller.current.value,
              )),
          const SizedBox(height: 28),
          Obx(() {
            final last = controller.isLast;
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.next,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Row(
                    key: ValueKey(last),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        last ? 'begin_journey'.tr : 'next'.tr,
                        style: context.text.titleMedium?.copyWith(color: Colors.white),
                      ),
                      if (!last) ...[
                        const SizedBox(width: 8),
                        _DirectionalArrow(color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Forward arrow that flips to match the ambient text direction.
class _DirectionalArrow extends StatelessWidget {
  const _DirectionalArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: rtl,
      child: Icon(Icons.arrow_forward_rounded, size: 20, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Animated page indicator dots
// ─────────────────────────────────────────────────────────────────────────
class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key, required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == activeIndex ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == activeIndex ? context.colors.primary : context.athar.beige,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────

/// Screen 1 — a glowing light mark with radiating ripples (impact).
class _RipplePainter extends CustomPainter {
  _RipplePainter(this.primary, this.gold);

  final Color primary;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      ring.color = primary.withValues(alpha: 0.35 - i * 0.1);
      canvas.drawCircle(center, 18.0 + i * 15, ring);
    }

    // Central glowing gold mark.
    canvas.drawCircle(
      center,
      9,
      Paint()..color = gold.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, 6, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Screen 2 — growing streak arcs in gold with a completion tick.
class _StreakPainter extends CustomPainter {
  _StreakPainter(this.primary, this.gold);

  final Color primary;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    // Three concentric arcs of increasing sweep — a habit "growing".
    const sweeps = [0.45, 0.7, 0.95];
    for (var i = 0; i < sweeps.length; i++) {
      arc.color = i == sweeps.length - 1 ? gold : primary.withValues(alpha: 0.4);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 16.0 + i * 14),
        -math.pi / 2,
        2 * math.pi * sweeps[i],
        false,
        arc,
      );
    }

    // Center tick.
    final tick = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    final path = Path()
      ..moveTo(center.dx - 8, center.dy)
      ..lineTo(center.dx - 2, center.dy + 6)
      ..lineTo(center.dx + 9, center.dy - 7);
    canvas.drawPath(path, tick);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full-screen faint concentric ripples radiating from the bottom —
/// the ambient "impact" pattern behind every page.
class _AmbientRipples extends StatelessWidget {
  const _AmbientRipples();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: CustomPaint(
        painter: _AmbientRipplePainter(
          context.colors.primary,
          context.athar.gold,
        ),
      ),
    );
  }
}

class _AmbientRipplePainter extends CustomPainter {
  _AmbientRipplePainter(this.primary, this.gold);

  final Color primary;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 1.05);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var i = 0; i < 6; i++) {
      paint.color = (i.isEven ? primary : gold).withValues(alpha: 0.05);
      canvas.drawCircle(origin, size.height * 0.18 + i * (size.height * 0.14), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
