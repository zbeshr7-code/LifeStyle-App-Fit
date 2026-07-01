import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/main_controller.dart';
import '../../../core/constants/app_colors.dart';

class MainView extends GetView<MainController> {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      controller: controller.tabController,
      tabs: [
        PersistentTabConfig(
          screen: controller.pages[0],
          item: ItemConfig(
            icon: const Icon(Icons.fitness_center),
            title: 'workout'.tr,
            activeForegroundColor: AppColors.primary,
            inactiveForegroundColor: Colors.grey,
          ),
        ),
        PersistentTabConfig(
          screen: controller.pages[1],
          item: ItemConfig(
            icon: const Icon(Icons.restaurant),
            title: 'diet_plan'.tr,
            activeForegroundColor: AppColors.primary,
            inactiveForegroundColor: Colors.grey,
          ),
        ),
        PersistentTabConfig(
          screen: controller.pages[2],
          item: ItemConfig(
            icon: const Icon(Icons.directions_walk),
            title: 'step_counter'.tr,
            activeForegroundColor: AppColors.primary,
            inactiveForegroundColor: Colors.grey,
          ),
        ),
        PersistentTabConfig(
          screen: controller.pages[3],
          item: ItemConfig(
            icon: const Icon(Icons.chat_bubble_outline),
            title: 'chat_trainer'.tr,
            activeForegroundColor: AppColors.primary,
            inactiveForegroundColor: Colors.grey,
          ),
        ),
        PersistentTabConfig(
          screen: controller.pages[4],
          item: ItemConfig(
            icon: const Icon(Icons.person_outline),
            title: 'profile'.tr,
            activeForegroundColor: AppColors.primary,
            inactiveForegroundColor: Colors.grey,
          ),
        ),
      ],
      navBarBuilder: (navBarConfig) => Style4BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color: Theme.of(context).cardColor,
          padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
        ),
      ),
    );
  }
}
