import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: isDark ? _buildGlass(child) : _buildLightCard(child),
      ),
    );
  }

  Widget _buildGlass(Widget child) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLightCard(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSolid,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.surfaceBorder.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
