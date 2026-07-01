import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/theme_controller.dart';

@immutable
class AppColorScheme {
  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceSolid,
    required this.surfaceBorder,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconMuted,
    required this.primary,
    required this.primaryForeground,
    required this.error,
  });

  final Color background;
  final Color surface;
  final Color surfaceSolid;
  final Color surfaceBorder;
  final Color inputFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconMuted;
  final Color primary;
  final Color primaryForeground;
  final Color error;

  /// Dark — neon accent on charcoal (brand look).
  static const dark = AppColorScheme(
    background: Color(0xFF121212),
    surface: Color(0x0DFFFFFF),
    surfaceSolid: Color(0xFF1E1E1E),
    surfaceBorder: Color(0x1AFFFFFF),
    inputFill: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9E9E9E),
    iconMuted: Color(0xFF757575),
    primary: Color(0xFFD4FF1F),
    primaryForeground: Color(0xFF121212),
    error: Color(0xFFFF5252),
  );

  /// Light — warm neutrals + muted green (easier on the eyes).
  static const light = AppColorScheme(
    background: Color(0xFFF3F1EC),
    surface: Color(0xF2FFFCF8),
    surfaceSolid: Color(0xFFFFFCF8),
    surfaceBorder: Color(0x1A3D3832),
    inputFill: Color(0xFFE9E6E0),
    textPrimary: Color(0xFF2A2724),
    textSecondary: Color(0xFF6F6860),
    iconMuted: Color(0xFF9A928A),
    primary: Color(0xFF5A7F18),
    primaryForeground: Color(0xFFFFFFFF),
    error: Color(0xFFC94C4C),
  );
}

abstract final class AppColors {
  static AppColorScheme get _scheme {
    if (Get.isRegistered<ThemeController>()) {
      return Get.find<ThemeController>().colorScheme;
    }
    return AppColorScheme.dark;
  }

  static bool get isDark {
    if (Get.isRegistered<ThemeController>()) {
      return Get.find<ThemeController>().isDark;
    }
    return true;
  }

  static Color get background => _scheme.background;
  static Color get surface => _scheme.surface;
  static Color get surfaceSolid => _scheme.surfaceSolid;
  static Color get surfaceBorder => _scheme.surfaceBorder;
  static Color get inputFill => _scheme.inputFill;
  static Color get textPrimary => _scheme.textPrimary;
  static Color get textSecondary => _scheme.textSecondary;
  static Color get iconMuted => _scheme.iconMuted;
  static Color get primary => _scheme.primary;
  static Color get primaryForeground => _scheme.primaryForeground;
  static Color get error => _scheme.error;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double lg = 20;
  static const double xl = 40;
  static const double pill = 999;
}

abstract final class AppShadows {
  static List<BoxShadow> get soft {
    if (AppColors.isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
    }

    return [
      BoxShadow(
        color: const Color(0xFF3D3832).withValues(alpha: 0.07),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: const Color(0xFF3D3832).withValues(alpha: 0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
