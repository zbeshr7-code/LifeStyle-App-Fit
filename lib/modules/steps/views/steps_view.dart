import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/steps_controller.dart';
import '../../../core/constants/app_colors.dart';

class StepsView extends GetView<StepsController> {
  const StepsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('step_counter'.tr)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildStreakBadge(),
            SizedBox(height: 40.h),
            _buildStepCircle(),
            SizedBox(height: 40.h),
            _buildStatsGrid(),
            SizedBox(height: 30.h),
            _buildAverageInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Obx(() {
      if (controller.streakDays.value == 0) return const SizedBox.shrink();
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: AppColors.primary, size: 24.sp),
            SizedBox(width: 10.w),
            Text(
              'streak_message'.trParams({'days': controller.streakDays.value.toString()}),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStepCircle() {
    return Obx(() {
      double percent = controller.steps.value / controller.goal.value;
      if (percent > 1.0) percent = 1.0;
      if (percent < 0) percent = 0;

      return CircularPercentIndicator(
        radius: 120.r,
        lineWidth: 18.w,
        percent: percent,
        animation: true,
        animateFromLastPercent: true,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: AppColors.primary,
        backgroundColor: Theme.of(Get.context!).cardColor,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk, size: 48.sp, color: AppColors.primary),
            SizedBox(height: 8.h),
            Text(
              '${controller.steps.value}',
              style: TextStyle(fontSize: 44.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              '${'goal'.tr}: ${controller.goal.value}',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'distance'.tr,
            '${controller.distance.toStringAsFixed(2)}',
            'km'.tr,
            Icons.location_on,
            Colors.blue,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatCard(
            'calories'.tr,
            '${controller.calories.toStringAsFixed(0)}',
            'kcal'.tr,
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
          Text(
            '$unit $label',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageInfo() {
    return Obx(() => Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('avg_steps'.tr, style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              Text(
                '${controller.averageSteps.value} ${'steps'.tr}',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Icon(Icons.bar_chart, color: AppColors.primary, size: 32.sp),
        ],
      ),
    ));
  }
}
