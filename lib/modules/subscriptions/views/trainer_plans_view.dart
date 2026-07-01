import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_plans_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/widgets/trainer_revenue_summary_card.dart';

class TrainerPlansView extends GetView<TrainerPlansController> {
  const TrainerPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('subscription_trainer_plans_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Get.toNamed(AppRoutes.trainerSubscribers),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreatePlan,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        icon: const Icon(Icons.add),
        label: Text('subscription_add_plan'.tr),
      ),
      body: Obx(() {
        final loadingPlans =
            controller.status.value.isLoading && controller.plans.isEmpty;
        final hasError = controller.status.value.isError;
        final noPlans =
            !hasError && !loadingPlans && controller.plans.isEmpty;

        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              88,
            ),
            children: [
              const TrainerRevenueSummaryCard(),
              const SizedBox(height: AppSpacing.lg),
              if (loadingPlans)
                const Center(child: CircularProgressIndicator())
              else if (hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.errorMessage.value.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: controller.loadPlans,
                          child: Text('retry'.tr),
                        ),
                      ],
                    ),
                  ),
                )
              else if (noPlans)
                Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: Text('subscription_trainer_no_plans'.tr),
                  ),
                )
              else
                ...controller.plans.map(
                  (plan) => Card(
                    color: AppColors.surfaceSolid,
                    margin: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: ListTile(
                      title: Text(
                        plan.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${plan.priceAmount.toStringAsFixed(0)} ${'subscription_currency_sar'.tr} · ${plan.durationDays} ${'subscription_days'.tr}',
                      ),
                      trailing: plan.isActive
                          ? Icon(
                              plan.isFeatured ? Icons.star : Icons.check_circle,
                              color: plan.isFeatured
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            )
                          : Text(
                              'subscription_inactive'.tr,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                      onTap: plan.isActive
                          ? () => controller.openEditPlan(plan)
                          : null,
                      onLongPress: plan.isActive
                          ? () => _showPlanActions(context, plan)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _showPlanActions(BuildContext context, SubscriptionPlanModel plan) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceSolid,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('subscription_edit_plan'.tr),
              onTap: () {
                Navigator.pop(ctx);
                controller.openEditPlan(plan);
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility_off, color: AppColors.error),
              title: Text('subscription_deactivate_plan'.tr),
              onTap: () {
                Navigator.pop(ctx);
                controller.deactivatePlan(plan);
              },
            ),
          ],
        ),
      ),
    );
  }
}
