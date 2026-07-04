import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/models/auth_method.dart';

class AuthMethodTabs extends StatelessWidget {
  const AuthMethodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AuthMethod selected;
  final ValueChanged<AuthMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSolid,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'auth_method_email'.tr,
              isSelected: selected == AuthMethod.email,
              onTap: () => onChanged(AuthMethod.email),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'auth_method_phone'.tr,
              isSelected: selected == AuthMethod.phone,
              onTap: () => onChanged(AuthMethod.phone),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppColors.primaryForeground
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
