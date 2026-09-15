import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';

/// Short confirmations and errors, in the active theme's colours.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    bool isError = false,
  }) {
    final context = Get.context!;
    final scheme = Theme.of(context).colorScheme;
    final background = isError ? scheme.error : scheme.inverseSurface;
    final foreground = isError ? scheme.onError : scheme.onInverseSurface;

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: background,
      colorText: foreground,
      borderRadius: AtharRadius.md,
      margin: const EdgeInsets.all(AtharSpace.md),
      duration: const Duration(seconds: 4),
      icon: Icon(
        isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
        color: isError ? foreground : context.athar.gold,
      ),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
    );
  }

  static void error(String title, String message, {SnackPosition position = SnackPosition.BOTTOM}) =>
      show(title, message, position: position, isError: true);
}
