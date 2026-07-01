import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class NutritionMealCard extends StatelessWidget {
  const NutritionMealCard({
    super.key,
    required this.meal,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });

  final NutritionMealModel meal;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canManage)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: Icon(
                    Icons.drag_handle,
                    color: AppColors.iconMuted,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      meal.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...meal.foodItemLines.map(
                      (line) => Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: AppColors.primary)),
                            Expanded(child: Text(line)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      '${'activity_calories'.tr}: ${meal.calories}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        meal.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('nutrition_edit_meal'.tr),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'nutrition_delete_confirm'.tr,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (meal.photoUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: CachedNetworkImage(
                imageUrl: meal.photoUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (_, __, ___) => const SizedBox(
                  height: 160,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
