import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../data/providers/storage_provider.dart';
import '../design/athar_scale.dart';
import '../design/athar_theme_presets.dart';
import 'app_theme.dart';

enum AppearanceMode { system, light, dark }

/// Owns the appearance preferences — colour theme, light/dark/system and text
/// & interface size — persists them on the device, and rebuilds the app when
/// one changes (main.dart listens with a GetBuilder).
class ThemeController extends GetxController {
  final StorageProvider _storage = Get.find<StorageProvider>();

  late AtharThemePreset preset = AtharThemePreset.byId(_storage.themePreset);
  late AppearanceMode appearance = _initialAppearance();
  late AtharTextSize textSize = AtharTextSize.byName(_storage.textSize);

  final _themes = <String, ThemeData>{};

  AppearanceMode _initialAppearance() {
    final stored = _storage.themeMode;
    for (final m in AppearanceMode.values) {
      if (m.name == stored) return m;
    }
    // Before the three-way setting the app stored only dark on/off, with off
    // as the default. A choice already made is kept; otherwise follow the
    // device.
    if (_storage.hasDarkModePreference) {
      return _storage.darkMode ? AppearanceMode.dark : AppearanceMode.light;
    }
    return AppearanceMode.system;
  }

  ThemeMode get mode => switch (appearance) {
        AppearanceMode.system => ThemeMode.system,
        AppearanceMode.light => ThemeMode.light,
        AppearanceMode.dark => ThemeMode.dark,
      };

  /// Whether the dark theme is showing right now.
  bool get isDark => switch (appearance) {
        AppearanceMode.dark => true,
        AppearanceMode.light => false,
        AppearanceMode.system =>
          SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
      };

  ThemeData lightTheme({required bool arabic}) => _theme(Brightness.light, arabic);
  ThemeData darkTheme({required bool arabic}) => _theme(Brightness.dark, arabic);

  ThemeData _theme(Brightness brightness, bool arabic) => _themes.putIfAbsent(
        '${preset.id}.${brightness.name}.$arabic',
        () => AppTheme.build(preset, brightness, arabic: arabic),
      );

  void setPreset(AtharThemePreset value) {
    if (value.id == preset.id) return;
    preset = value;
    _storage.themePreset = value.id;
    update();
  }

  void setAppearance(AppearanceMode value) {
    if (value == appearance) return;
    appearance = value;
    _storage.themeMode = value.name;
    update();
  }

  void setTextSize(AtharTextSize value) {
    if (value == textSize) return;
    textSize = value;
    _storage.textSize = value.name;
    update();
  }

  /// Flips between light and dark (the quick toggle on onboarding).
  void toggle() => setAppearance(isDark ? AppearanceMode.light : AppearanceMode.dark);
}
