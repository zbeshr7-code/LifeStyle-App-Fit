import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainee_plans_controller.dart';
import 'package:soccer_sys/modules/subscriptions/widgets/subscription_plan_card.dart';

class TraineePlansView extends GetView<TraineePlansController> {
  const TraineePlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('subscription_plans_title'.tr),
      ),
      body: Obx(() {
        if (controller.status.value.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.trainerId == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: Text(
                'subscription_need_trainer_body'.tr,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (controller.status.value.isEmpty) {
          return Center(child: Text('subscription_no_plans'.tr));
        }
        if (controller.status.value.isError) {
          return Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
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
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadPlans,
          child: ListView.separated(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            itemCount: controller.plans.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final plan = controller.plans[index];
              return SubscriptionPlanCard(
                plan: plan,
                onTap: () => controller.openCheckout(plan),
              );
            },
          ),
        );
      }),
    );
  }
}
