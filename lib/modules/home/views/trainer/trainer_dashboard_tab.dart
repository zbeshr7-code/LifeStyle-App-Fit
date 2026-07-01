import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/home/controllers/home_controller.dart';
import 'package:soccer_sys/modules/home/controllers/trainer_dashboard_controller.dart';
import 'package:soccer_sys/modules/home/widgets/home_header.dart';
import 'package:soccer_sys/modules/home/widgets/home_stat_card.dart';
import 'package:soccer_sys/modules/home/widgets/trainer_dashboard_cards.dart';

class TrainerDashboardTab extends GetView<TrainerDashboardController> {
  const TrainerDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;

    return Obx(() {
      final isLoading =
          controller.status.value.isLoading && controller.subscribers.isEmpty;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(
                user: user,
                subtitle: 'trainer_dashboard_subtitle'.tr,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TrainerOverviewCard(),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: HomeStatCard(
                            icon: Icons.groups_outlined,
                            label: 'trainer_stat_clients'.tr,
                            value: '${controller.clientCount}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: HomeStatCard(
                            icon: Icons.verified_outlined,
                            label: 'trainer_stat_active_subs'.tr,
                            value: '${controller.activeSubscriptionCount}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: HomeStatCard(
                            icon: Icons.card_membership_outlined,
                            label: 'trainer_stat_plans'.tr,
                            value:
                                '${controller.activePlanCount.value}/${controller.planCount.value}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: HomeStatCard(
                            icon: Icons.payments_outlined,
                            label: 'trainer_revenue_month'.tr,
                            value: controller.revenueThisMonth.value != null
                                ? controller.revenueThisMonth.value!
                                    .paidAmount
                                    .toStringAsFixed(0)
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsetsDirectional.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      const TrainerSubscriptionSummaryCard(),
                      const SizedBox(height: AppSpacing.lg),
                      const TrainerRecentSubscribersCard(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    HomeSectionTitle(title: 'dashboard_quick_access'.tr),
                    HomeQuickTile(
                      icon: Icons.card_membership_outlined,
                      title: 'subscription_trainer_plans_title'.tr,
                      subtitle: 'subscription_trainer_plans_desc'.tr,
                      onTap: () =>
                          Get.toNamed(AppRoutes.trainerSubscriptionPlans),
                    ),
                    HomeQuickTile(
                      icon: Icons.people_outline,
                      title: 'trainer_action_subscribers'.tr,
                      subtitle: 'trainer_action_subscribers_desc'.tr,
                      onTap: () => Get.toNamed(AppRoutes.trainerSubscribers),
                    ),
                    HomeQuickTile(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'subscription_assign_title'.tr,
                      subtitle: 'trainer_action_assign_sub_desc'.tr,
                      onTap: () =>
                          Get.toNamed(AppRoutes.trainerAssignSubscription),
                    ),
                    HomeQuickTile(
                      icon: Icons.groups_outlined,
                      title: 'nav_clients'.tr,
                      subtitle: 'trainer_clients_subtitle'.tr,
                      onTap: () => Get.find<HomeController>().changeTab(1),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
