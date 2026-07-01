import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkoutExerciseCard extends StatelessWidget {
  const WorkoutExerciseCard({
    super.key,
    required this.exercise,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });

  final WorkoutExerciseModel exercise;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Future<void> _openVideo() async {
    final url = exercise.videoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canManage)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: Icon(Icons.drag_handle, color: AppColors.iconMuted),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (exercise.sets != null)
                      Text('${'workout_sets'.tr}: ${exercise.sets}'),
                    if (exercise.reps != null)
                      Text('${'workout_reps'.tr}: ${exercise.reps}'),
                    if (exercise.targetWeightKg != null)
                      Text(
                        '${'workout_target_weight'.tr}: ${exercise.targetWeightKg} kg',
                      ),
                    if (exercise.notes != null &&
                        exercise.notes!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        exercise.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('workout_edit_exercise'.tr),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'workout_delete_confirm'.tr,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (exercise.photoUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: CachedNetworkImage(
                imageUrl: exercise.photoUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (exercise.hasVideo) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _openVideo,
              icon: const Icon(Icons.play_circle_outline),
              label: Text('workout_video'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
