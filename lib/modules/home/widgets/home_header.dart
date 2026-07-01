import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.subtitle,
    this.user,
  });

  final String subtitle;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user != null
                      ? '${'home_welcome'.tr}, ${user!.firstName}'
                      : 'home_welcome'.tr,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (user != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _RoleChip(role: user!.role),
                ],
              ],
            ),
          ),
          _AvatarInitials(name: user?.fullName ?? '?', avatarUrl: user?.avatarUrl),
          SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: authController.logout,
            icon:  Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'logout'.tr,
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final label =
        role == UserRole.trainer ? 'role_trainer'.tr : 'role_trainee'.tr;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
              ),
        ),
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _InitialText(initial: initial),
              errorWidget: (_, __, ___) => _InitialText(initial: initial),
            )
          : _InitialText(initial: initial),
    );
  }
}

class _InitialText extends StatelessWidget {
  const _InitialText({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
