import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/workout_controller.dart';

class WorkoutView extends GetView<WorkoutController> {
  const WorkoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('workout_schedule'.tr)),
      body: Column(
        children: [
          _buildDaysHeader(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              return Stack(
                children: [
                  _buildExerciseList(),
                  if (!controller.hasAccess.value) _buildLockOverlay(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysHeader() {
    final dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return Container(
      height: 90.h,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        itemBuilder: (context, index) {
          return Obx(() {
            bool isSelected = controller.selectedDayIndex.value == index;
            // Find plan for this day
            final dayPlan = controller.workoutPlans.firstWhere(
              (p) => p['day_of_week'] == index,
              orElse: () => null,
            );
            String type = dayPlan?['type'] ?? 'rest';

            return GestureDetector(
              onTap: () => controller.selectDay(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80.w,
                margin: EdgeInsets.symmetric(horizontal: 5.w),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayKeys[index].tr,
                      style: TextStyle(
                        color: isSelected ? Colors.black : null,
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      type.tr,
                      style: TextStyle(
                        color: isSelected ? Colors.black54 : Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildExerciseList() {
    final currentDayPlans = controller.workoutPlans.where(
      (p) => p['day_of_week'] == controller.selectedDayIndex.value
    ).toList();

    if (currentDayPlans.isEmpty || (currentDayPlans.first['exercises'] as List).isEmpty) {
      return Center(
        child: Text(
          'rest'.tr,
          style: TextStyle(fontSize: 18.sp, color: Colors.grey),
        ),
      );
    }

    final exercises = currentDayPlans.first['exercises'] as List;

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ex = exercises[index];
        return Container(
          margin: EdgeInsets.only(bottom: 15.h),
          padding: EdgeInsets.all(15.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  image: ex['image_url'] != null ? DecorationImage(
                    image: NetworkImage(ex['image_url']),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: ex['video_url'] != null ? const Icon(Icons.play_circle_fill, color: AppColors.primary) : null,
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex['title'] ?? '',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${ex['sets']} ${'sets'.tr} x ${ex['reps']} ${'reps'.tr} • ${ex['weight']}${'weight_unit'.tr}',
                      style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              if (ex['is_pr_attempt'] == true)
                Tooltip(
                  message: 'pr_attempt'.tr,
                  child: Icon(Icons.star, color: Colors.amber, size: 22.sp),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: AppColors.primary, size: 80.sp),
          SizedBox(height: 20.h),
          Text(
            'locked_content'.tr,
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              'subscribe_message'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: () => Get.toNamed('/subscriptions'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(220.w, 56.h),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: Text('subscribe_now'.tr),
          )
        ],
      ),
    );
  }
}
