import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/ui/athar_ui.dart';
import 'splash_controller.dart';

/// Splash: the brand ground, the animated logo with the tagline under it, and
/// a quiet loading indicator at the foot. The controller handles navigation
/// once the logo has played and startup settles.
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
        body: SafeArea(
          child: Stack(
            children: [
              Center(child: _AnimatedLogo(onShown: controller.logoShown)),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: AtharSpace.xxl,
                child: Center(
                  child: Semantics(
                    label: 'splash_loading'.tr,
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(context.athar.gold.withValues(alpha: 0.85)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The أثر logo, drawn in by its Lottie animation (assets/lottie/
/// athar_logo.json) once, at its own pace, with the tagline fading in under
/// it as the wordmark appears. Reports [onShown] when it has finished — at
/// once, on its last frame, when motion is reduced — and falls back to the
/// static banner if the animation can't load.
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo({required this.onShown});

  final VoidCallback onShown;

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  /// The finished logo stays a moment before the app moves on.
  static const _hold = Duration(milliseconds: 400);

  /// Where in the logo's animation the tagline fades in: as the wordmark
  /// settles (frames ~70–100 of 165).
  static const _taglineIn = Interval(0.42, 0.62, curve: Curves.easeOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLoaded(LottieComposition composition) {
    if (!mounted) return;
    _controller.duration = composition.duration;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      Future<void>.delayed(const Duration(milliseconds: 1200), widget.onShown);
      return;
    }
    _controller.forward().whenCompleteOrCancel(() => Future<void>.delayed(_hold, widget.onShown));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.70;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'app_name'.tr,
          image: true,
          child: Lottie.asset(
            'assets/lottie/athar_logo.json',
            controller: _controller,
            width: width,
            fit: BoxFit.contain,
            onLoaded: _onLoaded,
            errorBuilder: (context, error, stack) {
              // Nothing to wait for; the banner shows for the usual short while.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _controller.value = 1; // the tagline shows in full with it
                widget.onShown();
              });
              return const _BrandBanner();
            },
          ),
        ),
        const SizedBox(height: AtharSpace.lg),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _taglineIn.transform(_controller.value);
            return Opacity(
              opacity: t,
              // Rises a few pixels as it appears.
              child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
            );
          },
          child: _Tagline(width: width),
        ),
      ],
    );
  }
}

/// The brand tagline in both languages, whatever the app's own: Arabic first
/// (سَكِينَةُ اليَوْم.. وَأَثَرُ العُمُر), English under it, smaller and softer
/// (Daily Tranquility, Lasting Impact). Both come from `brand_tagline` in the
/// translations, so the wording lives in one place.
class _Tagline extends StatelessWidget {
  const _Tagline({required this.width});

  final double width;

  static String _in(String language) => Get.translations[language]?['brand_tagline'] ?? '';

  @override
  Widget build(BuildContext context) {
    final gold = context.athar.gold;
    final arabic = _in('ar');
    final english = _in('en');

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arabic.isNotEmpty)
            Text(
              arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              style: context.type.sectionTitle.copyWith(
                fontFamily: AtharFonts.arabic,
                color: gold.withValues(alpha: 0.92),
                fontWeight: FontWeight.w500,
                height: 1.7,
              ),
            ),
          if (english.isNotEmpty) ...[
            const SizedBox(height: AtharSpace.xxs),
            Text(
              english,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 2,
              style: context.type.body.copyWith(
                fontFamily: AtharFonts.latin,
                color: gold.withValues(alpha: 0.7),
                height: 1.4,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The static banner, used when the animated logo can't load. Falls back to
/// the أثر wordmark if the banner asset is missing too, so the splash never
/// renders blank.
class _BrandBanner extends StatelessWidget {
  const _BrandBanner();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/banner.png',
      width: MediaQuery.sizeOf(context).width * 0.70,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Text(
        'أثر',
        style: context.text.displayLarge?.copyWith(color: context.athar.gold),
      ),
    );
  }
}
