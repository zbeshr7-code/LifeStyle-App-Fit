import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/core/utils/phone_utils.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/shared/widgets/auth_widgets.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class PhoneOtpView extends GetView<AuthController> {
  const PhoneOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = controller.pendingPhoneE164.value ?? '';

    return AuthScaffold(
      title: 'otp_title'.tr,
      subtitle: 'otp_subtitle'.trParams({
        'phone': PhoneUtils.mask(phone),
      }),
      child: Obx(() {
        final isLoading = controller.status.value.isLoading;
        final cooldown = controller.resendCooldown.value;

        return GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.errorMessage.isNotEmpty)
                ErrorBanner(message: controller.errorMessage.value),
              AppTextField(
                label: 'otp_code'.tr,
                hint: 'otp_code_hint'.tr,
                controller: controller.otpController,
                icon: Icons.sms_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: cooldown > 0 ? null : controller.resendPhoneOtp,
                  child: Text(
                    cooldown > 0
                        ? 'otp_resend_in'.trParams({'seconds': '$cooldown'})
                        : 'otp_resend'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cooldown > 0
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'otp_verify'.tr,
                isLoading: isLoading,
                onPressed: controller.verifyPhoneOtp,
              ),
            ],
          ),
        );
      }),
    );
  }
}
