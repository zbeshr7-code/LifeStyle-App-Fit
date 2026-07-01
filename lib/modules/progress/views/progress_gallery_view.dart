import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/progress/controllers/progress_gallery_controller.dart';
import 'package:soccer_sys/modules/progress/widgets/progress_photo_grid.dart';
import 'package:soccer_sys/modules/progress/widgets/progress_stats_header.dart';
import 'package:soccer_sys/modules/progress/widgets/progress_timeline_header.dart';

class ProgressGalleryView extends GetView<ProgressGalleryController> {
  const ProgressGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('progress_gallery_title'.tr),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        onPressed: controller.openAddEntry,
        child: const Icon(Icons.add_a_photo),
      ),
      body: Obx(() {
        if (controller.status.value.isLoading && controller.entries.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.status.value.isError && controller.entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: controller.loadEntries,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (controller.photoCount == 0) {
          return _EmptyState(onAdd: controller.openAddEntry);
        }

        final groups = controller.groupedByMonth;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadEntries,
          child: ListView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            children: [
              const ProgressStatsHeader(),
              ...groups.expand((group) {
                return [
                  ProgressTimelineHeader(title: group.key),
                  ProgressPhotoGrid(
                    items: group.value,
                    onPhotoTap: controller.openPhotoDetail,
                  ),
                ];
              }),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'progress_empty_title'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'progress_empty_subtitle'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo),
              label: Text('progress_add_entry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
