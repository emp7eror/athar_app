import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/ui/athar_ui.dart';
import 'onboarding_controller.dart';

/// A first, calm introduction to Athar: one idea per page, with the language
/// and appearance within reach.
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
// Top bar: language, light/dark, and skip
// ─────────────────────────────────────────────────────────────────────────
class _TopControls extends StatelessWidget {
  const _TopControls();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    final theme = Get.find<ThemeController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AtharSpace.sm, AtharSpace.xs, AtharSpace.sm, 0),
      child: Row(
        children: [
          AtharIconButton(
            icon: Icons.translate_rounded,
            tooltip: 'language'.tr,
            onPressed: Get.find<LocalizationController>().toggle,
          ),
          GetBuilder<ThemeController>(
            builder: (t) => AtharIconButton(
              icon: t.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              tooltip: 'appearance_mode'.tr,
              onPressed: theme.toggle,
            ),
          ),
          const Spacer(),
          Obx(
            () => AnimatedOpacity(
              duration: AtharMotion.base,
              opacity: controller.isLast ? 0 : 1,
              child: TextButton(
                onPressed: controller.isLast ? null : controller.skip,
                child: Text('skip'.tr),
              ),
            ),
          ),
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
// Single page: motif emblem, title, subtitle
// ─────────────────────────────────────────────────────────────────────────
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key, required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.xl, vertical: AtharSpace.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MotifEmblem(motif: page.motif),
          const SizedBox(height: AtharSpace.xxl),
          Semantics(
            header: true,
            child: Text(
              page.titleKey.tr,
              textAlign: TextAlign.center,
              style: context.text.headlineMedium?.copyWith(color: context.colors.primary),
            ),
          ),
          const SizedBox(height: AtharSpace.md),
          Text(
            page.subtitleKey.tr,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
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
    final primary = context.colors.primary;

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
                color: primary.withValues(alpha: d == 220 ? 0.04 : 0.06),
              ),
            ),
          // Beige core disc.
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.athar.beige,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
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
            Text('app_name'.tr, style: context.text.displayMedium?.copyWith(color: primary)),
            PositionedDirectional(
              top: -2,
              end: -6,
              child: Icon(Icons.auto_awesome_rounded, size: 22, color: gold),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bottom: page indicator and the way onward
// ─────────────────────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  const _BottomControls();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.xs, AtharSpace.lg, AtharSpace.lg),
      child: Column(
        children: [
          Obx(
            () => PageIndicator(
              count: OnboardingController.pages.length,
              activeIndex: controller.current.value,
            ),
          ),
          const SizedBox(height: AtharSpace.lg),
          Obx(
            () => AtharButton(
              label: controller.isLast ? 'begin_journey'.tr : 'next'.tr,
              icon: controller.isLast ? null : Icons.arrow_forward_rounded,
              expand: true,
              onPressed: controller.next,
            ),
          ),
        ],
      ),
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
    return Semantics(
      label: '${activeIndex + 1} / $count',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AtharMotion.slow,
              curve: AtharMotion.standard,
              margin: const EdgeInsets.symmetric(horizontal: AtharSpace.xxs),
              width: i == activeIndex ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == activeIndex ? context.colors.primary : context.athar.beige,
                borderRadius: BorderRadius.circular(AtharRadius.pill),
              ),
            ),
        ],
      ),
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
      Paint()
        ..color = gold.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
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

/// Full-screen faint concentric ripples radiating from the bottom — the
/// ambient "impact" pattern behind every page.
class _AmbientRipples extends StatelessWidget {
  const _AmbientRipples();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: CustomPaint(
        painter: _AmbientRipplePainter(context.colors.primary, context.athar.gold),
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
