import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/widgets/role_selector.dart';
import 'package:soccer_sys/modules/auth/widgets/terms_checkbox.dart';
import 'package:soccer_sys/shared/widgets/auth_widgets.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'register_title'.tr,
      subtitle: 'register_subtitle'.tr,
      footer: _AuthLink(
        prefix: 'already_have_account'.tr,
        link: 'login_link'.tr,
        onTap: () => Get.offNamed(AppRoutes.login),
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
                label: 'full_name'.tr,
                hint: 'full_name_hint'.tr,
                controller: controller.fullNameController,
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'confirm_password'.tr,
                hint: 'password_hint'.tr,
                controller: controller.confirmPasswordController,
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              RoleSelector(
                selectedRole: controller.selectedRole.value,
                onChanged: (role) => controller.selectedRole.value = role,
              ),
              const SizedBox(height: AppSpacing.md),
              TermsCheckbox(
                value: controller.termsAccepted.value,
                onChanged: (value) => controller.termsAccepted.value = value,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'create_account'.tr,
                isLoading: isLoading,
                onPressed: controller.register,
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
