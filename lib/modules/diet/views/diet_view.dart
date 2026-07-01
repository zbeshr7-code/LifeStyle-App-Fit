import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/diet_controller.dart';

class DietView extends GetView<DietController> {
  const DietView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('diet_plan'.tr),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'meals'.tr),
              Tab(text: 'calories'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Obx(() => controller.isLoading.value 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildMealsList()),
            Obx(() => controller.isLoading.value 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildCaloriesSummary()),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsList() {
    final meals = controller.mealPlan['meals'] as List? ?? [];
    
    if (meals.isEmpty) {
      return Center(child: Text('no_data'.tr, style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Container(
          margin: EdgeInsets.only(bottom: 15.h),
          padding: EdgeInsets.all(20.w),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'meal'.tr} ${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      meal['description'] ?? '',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Text(
                meal['time'] ?? '',
                style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaloriesSummary() {
    final plan = controller.mealPlan;
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Text('calorie_goal'.tr, style: TextStyle(fontSize: 18.sp, color: Colors.grey)),
          SizedBox(height: 10.h),
          Text(
            '${plan['calories_goal'] ?? 0}',
            style: TextStyle(fontSize: 64.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          Text('kcal'.tr, style: TextStyle(fontSize: 18.sp, color: Colors.grey)),
          SizedBox(height: 40.h),
          _buildMacroRow('protein'.tr, '${plan['protein_goal'] ?? 0}'),
          SizedBox(height: 16.h),
          _buildMacroRow('carbs'.tr, '${plan['carbs_goal'] ?? 0}'),
          SizedBox(height: 16.h),
          _buildMacroRow('fat'.tr, '${plan['fat_goal'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, String value) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          Text('$value ${'g'.tr}', style: TextStyle(fontSize: 16.sp, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
