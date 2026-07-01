import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/progress/controllers/progress_gallery_controller.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class ProgressStatsHeader extends GetView<ProgressGalleryController> {
  const ProgressStatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final first = controller.firstWeight;
      final latest = controller.latestWeight;
      String? deltaLabel;
      if (first != null && latest != null && first != latest) {
        final delta = latest - first;
        final sign = delta > 0 ? '+' : '';
        deltaLabel = '$sign${delta.toStringAsFixed(1)} kg';
      }

      return GlassContainer(
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.collections_outlined,
                label: 'progress_stat_photos'.tr,
                value: '${controller.photoCount}',
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.timeline,
                label: 'progress_stat_entries'.tr,
                value: '${controller.entryCount}',
              ),
            ),
            if (latest != null)
              Expanded(
                child: _StatItem(
                  icon: Icons.monitor_weight_outlined,
                  label: 'progress_stat_weight'.tr,
                  value: deltaLabel != null
                      ? '${latest.toStringAsFixed(1)} ($deltaLabel)'
                      : latest.toStringAsFixed(1),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
