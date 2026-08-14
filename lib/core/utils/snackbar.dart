import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  AppSnackbar._();

  static void show(
      String title,      // ← positional
      String message,    // ← positional
          {
        SnackPosition position = SnackPosition.BOTTOM,
        bool isError = false,
      }
      ) {
    final theme = Theme.of(Get.context!).snackBarTheme;

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: isError ? const Color(0xFFB00020) : theme.backgroundColor,
      colorText: theme.contentTextStyle?.color ?? Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 5),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: isError ? Colors.white70 : const Color(0xFFE0A458),
      ),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
    );
  }

  static void error(String title, String message, {SnackPosition position = SnackPosition.BOTTOM}) =>
      show(title, message, position: position, isError: true);
}