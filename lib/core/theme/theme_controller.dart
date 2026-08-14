import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/providers/storage_provider.dart';

/// Owns the light/dark preference, persists it, and drives GetX's theme mode.
class ThemeController extends GetxController {
  final StorageProvider _storage = Get.find<StorageProvider>();

  bool get isDark => _storage.darkMode;

  ThemeMode get mode => isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _storage.darkMode = !_storage.darkMode;
    Get.changeThemeMode(mode); // rebuilds the whole GetMaterialApp tree
  }
}
