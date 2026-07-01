import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moyasar/moyasar.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/subscription_controller.dart';
import '../../../data/models/subscription_plan_model.dart';

class SubscriptionView extends GetView<SubscriptionController> {
  const SubscriptionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('subscription_plans'.tr),
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.plans.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return ListView.builder(
          padding: EdgeInsets.all(20.w),
          itemCount: controller.plans.length,
          itemBuilder: (context, index) {
            final plan = controller.plans[index];
            return _buildPlanCard(context, plan);
          },
        );
      }),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan) {
    final isPro = plan.nameEn.contains('Pro') || plan.nameEn.contains('Elite');

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isPro ? AppColors.primary : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: (isPro ? AppColors.primary : Colors.black).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: isPro ? Colors.black : null,
                ),
              ),
              if (isPro)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'MOST POPULAR'.tr,
                    style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            plan.description ?? '',
            style: TextStyle(
              fontSize: 14.sp,
              color: isPro ? Colors.black87 : Colors.grey,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${plan.price.toStringAsFixed(0)} ${'sar'.tr}',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w900,
                  color: isPro ? Colors.black : AppColors.primary,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 6.h, left: 4.w),
                child: Text(
                  '/ ${plan.durationDays} ${'days'.tr}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isPro ? Colors.black54 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          const Divider(height: 1),
          SizedBox(height: 24.h),
          ...plan.features.map((feature) => _buildFeatureItem(feature, isPro)),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: () => _showPaymentSheet(context, plan),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPro ? Colors.black : AppColors.primary,
              foregroundColor: isPro ? Colors.white : Colors.black,
              minimumSize: Size(double.infinity, 56.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            child: Text('subscribe_now'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, SubscriptionPlan plan) {
    // Moyasar Integration Setup
    final paymentConfig = PaymentConfig(
      publishableApiKey: 'YOUR_MOYASAR_PUBLISHABLE_KEY', // Replace with real key
      amount: (plan.price * 100).toInt(), // Moyasar expects amount in subunits (halalas)
      description: plan.name,
      metadata: {'plan_id': plan.id},
      currency: 'SAR',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 0.8.sh,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Text('payment_details'.tr, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Expanded(
              child: CreditCard(
                config: paymentConfig,
                onPaymentResult: (result) {
                  if (result is PaymentResponse) {
                    if (result.status == PaymentStatus.captured) {
                      controller.subscribe(plan.id);
                      Get.back();
                    } else {
                      Get.snackbar('error'.tr, 'payment_failed'.tr);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature, bool isPro) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: isPro ? Colors.black : AppColors.primary,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14.sp,
                color: isPro ? Colors.black : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
