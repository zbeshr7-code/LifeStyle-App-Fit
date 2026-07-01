import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AppColors.isDark
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: _navDecor(
                  child: _navRow(
                    items: items,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ),
              )
            : _navDecor(
                child: _navRow(
                  items: items,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
              ),
      ),
    );
  }

  static Widget _navDecor({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? AppColors.surfaceSolid.withValues(alpha: 0.85)
            : AppColors.surfaceSolid,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.surfaceBorder.withValues(
            alpha: AppColors.isDark ? 1 : 0.65,
          ),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }

  static Widget _navRow({
    required List<GlassNavItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Expanded(
          child: _NavButton(
            item: item,
            isSelected: index == currentIndex,
            onTap: () => onTap(index),
          ),
        );
      }),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? AppColors.primary : AppColors.iconMuted,
                    size: 24,
                  ),
                  if (item.badgeCount > 0)
                    PositionedDirectional(
                      top: -4,
                      end: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryForeground,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
