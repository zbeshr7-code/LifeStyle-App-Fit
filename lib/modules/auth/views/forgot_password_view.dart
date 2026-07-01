import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/shared/widgets/auth_widgets.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'forgot_title'.tr,
      subtitle: 'forgot_subtitle'.tr,
      footer: Center(
        child: TextButton(
          onPressed: () => Get.offNamed(AppRoutes.login),
          child: Text(
            'back_to_login'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
      child: Obx(() {
        final isLoading = controller.status.value.isLoading;
        final isSuccess = controller.status.value.isSuccess;

        return GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.errorMessage.isNotEmpty)
                ErrorBanner(message: controller.errorMessage.value),
              if (isSuccess)
                Container(
                  margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'success_reset'.tr,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
              AppTextField(
                label: 'email'.tr,
                hint: 'email_hint'.tr,
                controller: controller.emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'send_reset_link'.tr,
                isLoading: isLoading,
                onPressed: controller.forgotPassword,
              ),
            ],
          ),
        );
      }),
    );
  }
}
