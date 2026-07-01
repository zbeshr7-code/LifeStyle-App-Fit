import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_day_tile.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainee_activity_history_controller.dart';

class TraineeActivityHistoryView
    extends GetView<TraineeActivityHistoryController> {
  const TraineeActivityHistoryView({super.key});

  void _openDay(DailyActivityModel activity) {
    Get.toNamed(
      AppRoutes.activityDay,
      arguments: ActivityDayArgs(
        date: activity.activityDate,
        activity: activity,
        traineeContext: controller.context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('trainer_client_activity_history'.tr),
      ),
      body: Obx(() {
        if (controller.status.value.isLoading &&
            controller.activities.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.status.value.isError &&
            controller.activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.errorMessage.value),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: controller.reloadHistory,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (controller.activities.isEmpty) {
          return Center(
            child: Text(
              'activity_no_history'.tr,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final groups = controller.groupedByMonth;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.reloadHistory,
          child: ListView.builder(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            itemCount: groups.length + (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= groups.length) {
                controller.loadMore();
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final entry = groups.entries.elementAt(index);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...entry.value.map(
                    (activity) => StepsDayTile(
                      activity: activity,
                      onTap: () => _openDay(activity),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}
