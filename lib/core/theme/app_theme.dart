import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

abstract final class AppTheme {
  static ThemeData get dark => _build(AppColorScheme.dark, Brightness.dark);

  static ThemeData get light => _build(AppColorScheme.light, Brightness.light);

  static ThemeData _build(AppColorScheme colors, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.primaryForeground,
        secondary: colors.primary,
        onSecondary: colors.primaryForeground,
        surface: colors.surfaceSolid,
        onSurface: colors.textPrimary,
        error: colors.error,
        onError: colors.primaryForeground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: colors.surfaceBorder,
      cardColor: colors.surfaceSolid,
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceSolid,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceSolid,
        surfaceTintColor: Colors.transparent,
      ),
    );

    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: isLight
                ? colors.surfaceBorder.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colors.error, width: 1),
        ),
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        labelStyle:
            textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceSolid,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.surfaceBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.primaryForeground,
          elevation: isLight ? 0 : 1,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: colors.surfaceBorder),
      ),
    );
  }
}
