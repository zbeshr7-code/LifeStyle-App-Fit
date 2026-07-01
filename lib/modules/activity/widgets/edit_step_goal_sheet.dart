import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

class EditStepGoalSheet extends StatefulWidget {
  const EditStepGoalSheet({
    super.key,
    required this.currentGoal,
    required this.onSave,
  });

  final int currentGoal;
  final Future<void> Function(int goal) onSave;

  static Future<void> show({
    required int currentGoal,
    required Future<void> Function(int goal) onSave,
  }) {
    return Get.bottomSheet(
      EditStepGoalSheet(currentGoal: currentGoal, onSave: onSave),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<EditStepGoalSheet> createState() => _EditStepGoalSheetState();
}

class _EditStepGoalSheetState extends State<EditStepGoalSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentGoal}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final goal = int.tryParse(_controller.text.trim());
    if (goal == null || goal <= 0) return;
    setState(() => _saving = true);
    await widget.onSave(goal);
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceSolid.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'activity_edit_goal'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'activity_daily_goal'.tr,
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('activity_save_goal'.tr),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
