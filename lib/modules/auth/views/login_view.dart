import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/shared/widgets/auth_widgets.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'login_title'.tr,
      subtitle: 'login_subtitle'.tr,
      showBackButton: false,
      footer: _AuthLink(
        prefix: 'no_account'.tr,
        link: 'register_link'.tr,
        onTap: () => Get.toNamed(AppRoutes.register),
      ),
      child: Obx(() {
        final isLoading = controller.status.value.isLoading;

        return GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.errorMessage.isNotEmpty)
                ErrorBanner(message: controller.errorMessage.value),
              AppTextField(
                label: 'email'.tr,
                hint: 'email_hint'.tr,
                controller: controller.emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'password'.tr,
                hint: 'password_hint'.tr,
                controller: controller.passwordController,
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                  child: Text(
                    'forgot_password'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'login_button'.tr,
                isLoading: isLoading,
                onPressed: controller.login,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _AuthLink extends StatelessWidget {
  const _AuthLink({
    required this.prefix,
    required this.link,
    required this.onTap,
  });

  final String prefix;
  final String link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            prefix,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              link,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
