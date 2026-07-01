import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/progress_controller.dart';

class ProgressView extends GetView<ProgressController> {
  const ProgressView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('progress_tracking'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.progressPhotos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 80.sp, color: Colors.grey.withOpacity(0.5)),
                SizedBox(height: 16.h),
                Text('no_data'.tr, style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(20.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15.w,
            mainAxisSpacing: 15.h,
            childAspectRatio: 0.8,
          ),
          itemCount: controller.progressPhotos.length,
          itemBuilder: (context, index) {
            final photo = controller.progressPhotos[index];
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Column(
                  children: [
                    Expanded(
                      child: Image.network(
                        photo['image_url'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Text(
                            '${'week'.tr} ${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                          ),
                          if (photo['weight'] != null)
                            Text(
                              '${photo['weight']} ${'weight_unit'.tr}',
                              style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.addPhoto(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_a_photo, color: Colors.black),
      ),
    );
  }
}
