import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../../data/models/user_model.dart';
import '../../widgets/framed_avatar.dart';

/// The shareable achievement image — captured via [WidgetImageExporter] and
/// handed to the system share sheet. Fixed portrait aspect (story-friendly),
/// in the brand's colours.
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.newLevel,
    required this.totalPoints,
  });

  final String name;
  final String? avatarUrl;
  final LevelInfo newLevel;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    final athar = context.athar;
    const onBrand = Colors.white;

    return SizedBox(
      width: 360,
      height: 640,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [athar.brand, athar.primaryDark],
              ),
            ),
          ),
          const Positioned.fill(child: CustomPaint(painter: IslamicMotifPainter())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 44,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AtharSpace.xxs),
                    Text(
                      'Athar',
                      style: context.text.labelLarge?.copyWith(
                        color: onBrand.withValues(alpha: 0.7),
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    FramedAvatar(
                      name: name,
                      avatarUrl: avatarUrl,
                      frameAsset: newLevel.frame,
                      frameUrl: newLevel.frameUrl,
                      level: newLevel.level,
                      radius: 60,
                      backgroundColor: athar.gold,
                    ),
                    const SizedBox(height: AtharSpace.md),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        color: onBrand,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    _Pill(text: newLevel.displayName(isAr)),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, color: athar.gold, size: AtharSize.icon),
                        const SizedBox(width: AtharSpace.xs),
                        Text(
                          '$totalPoints ${'points'.tr}',
                          style: context.text.titleMedium?.copyWith(
                            color: onBrand,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    Text(
                      'أثر',
                      style: context.text.labelMedium?.copyWith(
                        color: onBrand.withValues(alpha: 0.4),
                        letterSpacing: 3,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A gold-outlined pill, used on both shareable cards.
class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AtharRadius.pill),
        border: Border.all(color: context.athar.gold, width: 1.4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.text.titleMedium?.copyWith(
          color: context.athar.gold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// A restrained repeating 8-point-star motif along the card's border, evoking
/// Islamic geometric ornamentation without being visually heavy. Shared by the
/// shareable cards.
class IslamicMotifPainter extends CustomPainter {
  const IslamicMotifPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    const step = 46.0;
    for (double x = -step; x < size.width + step; x += step) {
      _drawStar(canvas, paint, Offset(x, 18));
      _drawStar(canvas, paint, Offset(x, size.height - 18));
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center) {
    const points = 8;
    const outerR = 12.0;
    const innerR = 5.0;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * math.pi) / points;
      final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
