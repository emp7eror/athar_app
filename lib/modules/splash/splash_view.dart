import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/ui/athar_ui.dart';
import 'splash_controller.dart';

/// Splash: the brand ground, the banner, and a quiet loading indicator. The
/// controller handles navigation once startup settles.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Always the deep brand ground, whatever theme the app is in.
    final ground = AppTheme.darkBackground(Get.find<ThemeController>().preset);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const _BrandBanner(),
              const SizedBox(height: AtharSpace.xxl),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(context.athar.gold),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
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
        style: context.text.displayLarge?.copyWith(color: context.athar.gold),
      ),
    );
  }
}
