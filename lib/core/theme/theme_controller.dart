import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

export 'package:soccer_sys/core/theme/tokens.dart'
    show AppColorScheme, AppColors, AppRadius, AppShadows, AppSpacing;

class ThemeController extends GetxController {
  static const prefKey = 'app_theme_mode';

  final themeMode = ThemeMode.dark.obs;

  bool get isDark => themeMode.value == ThemeMode.dark;

  AppColorScheme get colorScheme =>
      isDark ? AppColorScheme.dark : AppColorScheme.light;

  String get currentThemeLabel =>
      isDark ? 'theme_dark'.tr : 'theme_light'.tr;

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefKey);
    themeMode.value = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> toggleTheme() =>
      setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
}
