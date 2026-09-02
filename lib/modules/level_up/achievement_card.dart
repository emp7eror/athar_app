import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../widgets/framed_avatar.dart';

/// The shareable achievement image — captured via [WidgetImageExporter] and
/// handed to the system share sheet. Fixed portrait aspect (story-friendly).
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

    return SizedBox(
      width: 360,
      height: 640,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _IslamicMotifPainter()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Image.asset('assets/images/logo.png', height: 44,
                        errorBuilder: (_, _, _) => const SizedBox.shrink()),
                    const SizedBox(height: 6),
                    const Text(
                      'Athar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
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
                      radius: 70,
                      backgroundColor: AppColors.secondary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.secondary, width: 1.4),
                      ),
                      child: Text(
                        newLevel.displayName(isAr),
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '$totalPoints ${'points'.tr}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'أثر',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 3,
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

/// A restrained repeating 8-point-star motif along the card's border,
/// evoking Islamic geometric ornamentation without being visually heavy.
class _IslamicMotifPainter extends CustomPainter {
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
