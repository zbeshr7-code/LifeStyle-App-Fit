import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../../workout/views/workout_view.dart';
import '../../diet/views/diet_view.dart';
import '../../profile/views/profile_view.dart';
import '../../steps/views/steps_view.dart';
import '../../chat/views/chat_view.dart';

class MainController extends GetxController {
  late PersistentTabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = PersistentTabController(initialIndex: 0);
  }

  final List<Widget> pages = [
    const WorkoutView(),
    const DietView(),
    const StepsView(),
    const ChatView(),
    const ProfileView(),
  ];

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
