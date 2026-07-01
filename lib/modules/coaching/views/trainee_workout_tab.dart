import 'package:flutter/material.dart';
import 'package:soccer_sys/modules/workouts/views/workout_weekly_view.dart';
class TraineeWorkoutTab extends StatelessWidget {
  const TraineeWorkoutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkoutWeeklyView(embedded: true);
  }
}
