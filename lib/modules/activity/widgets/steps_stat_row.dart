import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/home/widgets/home_stat_card.dart';

class StepsStatRow extends StatelessWidget {
  const StepsStatRow({
    super.key,
    required this.calories,
    required this.distanceKm,
  });

  final double calories;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: HomeStatCard(
            icon: Icons.local_fire_department_outlined,
            label: 'activity_calories'.tr,
            value: '${calories.round()} kcal',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: HomeStatCard(
            icon: Icons.route_outlined,
            label: 'activity_distance'.tr,
            value: '${distanceKm.toStringAsFixed(2)} km',
          ),
        ),
      ],
    );
  }
}
