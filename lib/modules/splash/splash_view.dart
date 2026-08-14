import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import 'splash_controller.dart';

/// Splash: brand background (#15201A), banner artwork, and a loading indicator.
/// The controller handles navigation once startup settles.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  static const _bg = Color(0xFF15201A);

  @override
  Widget build(BuildContext context) {
    final gold = context.athar.gold;
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            const _BrandBanner(),
            const SizedBox(height: 48),

            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(gold),
              ),
            ),
            const Spacer(flex: 2),

          ],
        ),
      ),
    );
  }
}

/// Falls back to the أثر wordmark if the banner asset is missing, so the
/// splash never renders blank.
class _BrandBanner extends StatelessWidget {
  const _BrandBanner();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/banner.png',
      width: MediaQuery.sizeOf(context).width * 0.8,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Text(
        'أثر',
        style: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w700,
          color: context.athar.gold,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }
}
