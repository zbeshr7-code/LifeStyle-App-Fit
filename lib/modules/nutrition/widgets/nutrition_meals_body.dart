import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/nutrition/controllers/nutrition_meals_controller.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';
import 'package:soccer_sys/modules/nutrition/widgets/nutrition_meal_card.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class NutritionMealsBody extends GetView<NutritionMealsController> {
  const NutritionMealsBody({
    super.key,
    this.showHeader = true,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final bool showHeader;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: padding.left,
            right: padding.right,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Obx(
            () => _DayTypeSelector(
              selected: controller.selectedDayType.value,
              onChanged: controller.selectDayType,
            ),
          ),
        ),
        Expanded(
          child: Obx(() => _buildContent(context)),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (controller.status.value.isLoading && controller.meals.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.status.value.isError && controller.meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.errorMessage.value,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: controller.loadMeals,
              child: Text('retry'.tr),
            ),
          ],
        ),
      );
    }

    if (controller.meals.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadMeals,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            if (showHeader) ...[
              Text(
                'nutrition_subtitle'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
            Text(
              controller.canManage
                  ? 'nutrition_empty_trainer'.tr
                  : 'nutrition_empty_trainee'.tr,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.loadMeals,
      child: controller.canManage
          ? ReorderableListView(
              padding: padding,
              physics: const AlwaysScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: controller.reorderMeals,
              header: _summaryHeader(context),
              children: [
                for (var i = 0; i < controller.meals.length; i++)
                  ReorderableDragStartListener(
                    key: ValueKey(controller.meals[i].id),
                    index: i,
                    child: NutritionMealCard(
                      meal: controller.meals[i],
                      canManage: true,
                      onEdit: () => controller.openEditMeal(controller.meals[i]),
                      onDelete: () => controller.deleteMeal(controller.meals[i]),
                    ),
                  ),
              ],
            )
          : ListView(
              padding: padding,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _summaryHeader(context),
                ...controller.meals.map(
                  (meal) => NutritionMealCard(meal: meal),
                ),
              ],
            ),
    );
  }

  Widget _summaryHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Text(
              'nutrition_subtitle'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          GlassContainer(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${'nutrition_total_calories'.tr}: ${controller.totalCalories}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (controller.isSavingOrder.value)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTypeSelector extends StatelessWidget {
  const _DayTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final NutritionDayType selected;
  final ValueChanged<NutritionDayType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DayChip(
            label: 'nutrition_day_workout'.tr,
            icon: Icons.fitness_center,
            selected: selected == NutritionDayType.workout,
            onTap: () => onChanged(NutritionDayType.workout),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DayChip(
            label: 'nutrition_day_rest'.tr,
            icon: Icons.hotel,
            selected: selected == NutritionDayType.rest,
            onTap: () => onChanged(NutritionDayType.rest),
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.surfaceSolid,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.iconMuted,
              ),
              SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
