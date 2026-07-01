import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'terms_agree'.tr,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TermsIndicator(isChecked: value),
          ],
        ),
      ),
    );
  }
}

class _TermsIndicator extends StatelessWidget {
  const _TermsIndicator({required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isChecked ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isChecked ? AppColors.primary : AppColors.iconMuted,
          width: 2,
        ),
      ),
      child: isChecked
          ?  Icon(Icons.check, size: 16, color: AppColors.primaryForeground)
          : null,
    );
  }
}
