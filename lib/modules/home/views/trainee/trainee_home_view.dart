import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/modules/activity/views/trainee_steps_tab.dart';
import 'package:soccer_sys/modules/chat/controllers/chat_controller.dart';
import 'package:soccer_sys/modules/chat/views/chat_rooms_view.dart';
import 'package:soccer_sys/modules/home/controllers/home_controller.dart';
import 'package:soccer_sys/modules/home/views/trainee/trainee_dashboard_tab.dart';
import 'package:soccer_sys/modules/home/views/trainee/trainee_workouts_tab.dart';
import 'package:soccer_sys/modules/profile/views/profile_view.dart';
import 'package:soccer_sys/modules/subscriptions/widgets/subscription_gate.dart';
import 'package:soccer_sys/shared/widgets/glass_bottom_nav.dart';

class TraineeHomeView extends GetView<HomeController> {
  const TraineeHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return Obx(
      () {
        final navItems = [
          GlassNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'nav_home'.tr,
          ),
          GlassNavItem(
            icon: Icons.fitness_center_outlined,
            activeIcon: Icons.fitness_center,
            label: 'nav_workouts'.tr,
          ),
          GlassNavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'nav_chats'.tr,
            badgeCount: chatController.totalUnreadCount,
          ),
          GlassNavItem(
            icon: Icons.show_chart_outlined,
            activeIcon: Icons.show_chart,
            label: 'nav_progress'.tr,
          ),
          GlassNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'nav_profile'.tr,
          ),
        ];

        final pages = [
          const SubscriptionGate(child: TraineeDashboardTab()),
          const SubscriptionGate(child: TraineeWorkoutsTab()),
          const ChatRoomsView(),
          const SubscriptionGate(child: TraineeStepsTab()),
          const ProfileView(),
        ];

        return SafeArea(
          child: Scaffold(
            body: IndexedStack(
              index: controller.currentTabIndex.value,
              children: pages,
            ),
            bottomNavigationBar: GlassBottomNav(
              items: navItems,
              currentIndex: controller.currentTabIndex.value,
              onTap: controller.changeTab,
            ),
          ),
        );
      },
    );
  }
}
