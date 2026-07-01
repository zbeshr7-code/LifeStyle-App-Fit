import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/modules/chat/controllers/chat_controller.dart';
import 'package:soccer_sys/modules/chat/views/chat_rooms_view.dart';
import 'package:soccer_sys/modules/home/controllers/home_controller.dart';
import 'package:soccer_sys/modules/home/views/trainer/trainer_clients_tab.dart';
import 'package:soccer_sys/modules/home/views/trainer/trainer_dashboard_tab.dart';
import 'package:soccer_sys/modules/profile/views/profile_view.dart';
import 'package:soccer_sys/shared/widgets/glass_bottom_nav.dart';

class TrainerHomeView extends GetView<HomeController> {
  const TrainerHomeView({super.key});

  static const _pages = <Widget>[
    TrainerDashboardTab(),
    TrainerClientsTab(),
    ChatRoomsView(),
    ProfileView(),
  ];

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
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups,
            label: 'nav_clients'.tr,
          ),
          GlassNavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'nav_chats'.tr,
            badgeCount: chatController.totalUnreadCount,
          ),
          GlassNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'nav_profile'.tr,
          ),
        ];

        return SafeArea(
          child: Scaffold(
            body: IndexedStack(
              index: controller.currentTabIndex.value,
              children: _pages,
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
