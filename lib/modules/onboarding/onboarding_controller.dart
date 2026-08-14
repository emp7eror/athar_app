import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Visual motif rendered on each onboarding page.
enum OnboardingMotif { ripple, streak, heart, journal, logo }

/// Immutable content model for a single onboarding page.
/// Titles/subtitles are translation keys resolved with GetX `.tr`.
@immutable
class OnboardingPage {
  const OnboardingPage({
    required this.titleKey,
    required this.subtitleKey,
    required this.motif,
  });

  final String titleKey;
  final String subtitleKey;
  final OnboardingMotif motif;
}

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt current = 0.obs;

  static const List<OnboardingPage> pages = [
    OnboardingPage(titleKey: 'ob1_title', subtitleKey: 'ob1_sub', motif: OnboardingMotif.ripple),
    OnboardingPage(titleKey: 'ob2_title', subtitleKey: 'ob2_sub', motif: OnboardingMotif.streak),
    OnboardingPage(titleKey: 'ob3_title', subtitleKey: 'ob3_sub', motif: OnboardingMotif.heart),
    OnboardingPage(titleKey: 'ob4_title', subtitleKey: 'ob4_sub', motif: OnboardingMotif.journal),
    OnboardingPage(titleKey: 'ob5_title', subtitleKey: 'ob5_sub', motif: OnboardingMotif.logo),
  ];

  bool get isLast => current.value == pages.length - 1;

  void onPageChanged(int index) => current.value = index;

  void next() {
    if (isLast) {
      finish();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void skip() => finish();

  /// Routes into the blocking permission gate, which resolves Location +
  /// Notifications and then advances to auth/home. `seenOnboarding` is persisted
  /// there once the gate is cleared, so a user who quits mid-permissions still
  /// sees onboarding again rather than getting stuck.
  void finish() {
    Get.offAllNamed('/permissions');
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
