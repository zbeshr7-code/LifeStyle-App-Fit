import 'package:flutter/material.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

class ProfileFieldTile extends StatelessWidget {
  const ProfileFieldTile({
    super.key,
    required this.label,
    required this.value,
    this.isLast = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ],
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: isLast ? 0 : AppSpacing.md),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AppSpacing.xs,
                ),
                child: content,
              ),
            ),
    );
  }
}
