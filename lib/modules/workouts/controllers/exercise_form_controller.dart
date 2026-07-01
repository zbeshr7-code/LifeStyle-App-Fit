import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/modules/workouts/repositories/workout_repository.dart';

class ExerciseFormController extends GetxController {
  ExerciseFormController(this._repository, this.args);

  final WorkoutRepository _repository;
  final ExerciseFormArgs args;

  late final TextEditingController nameController;
  late final TextEditingController setsController;
  late final TextEditingController repsController;
  late final TextEditingController weightController;
  late final TextEditingController videoUrlController;
  late final TextEditingController notesController;

  final isSaving = false.obs;
  final pickedPhotoBytes = Rxn<Uint8List>();
  final pickedPhotoName = RxnString();
  final existingPhotoUrl = RxnString();
  final removeExistingPhoto = false.obs;

  final _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final exercise = args.exercise;
    nameController = TextEditingController(text: exercise?.name ?? '');
    setsController =
        TextEditingController(text: exercise?.sets?.toString() ?? '');
    repsController =
        TextEditingController(text: exercise?.reps?.toString() ?? '');
    weightController = TextEditingController(
      text: exercise?.targetWeightKg?.toString() ?? '',
    );
    videoUrlController =
        TextEditingController(text: exercise?.videoUrl ?? '');
    notesController = TextEditingController(text: exercise?.notes ?? '');
    existingPhotoUrl.value = exercise?.photoUrl;
  }

  @override
  void onClose() {
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    videoUrlController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    pickedPhotoBytes.value = await file.readAsBytes();
    pickedPhotoName.value = file.name;
    removeExistingPhoto.value = false;
  }

  void clearPhoto() {
    pickedPhotoBytes.value = null;
    pickedPhotoName.value = null;
    existingPhotoUrl.value = null;
    removeExistingPhoto.value = true;
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('', 'workout_exercise_name_required'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSaving.value = true;
    final sets = _positiveInt(setsController.text);
    final reps = _positiveInt(repsController.text);
    final weight = _nonNegativeDouble(weightController.text);
    final videoUrl = videoUrlController.text.trim();
    final notes = notesController.text.trim();

    if (args.isEditing) {
      final draft = args.exercise!.copyWith(
        name: name,
        sets: sets,
        reps: reps,
        targetWeightKg: weight,
        videoUrl: videoUrl.isEmpty ? null : videoUrl,
        notes: notes.isEmpty ? null : notes,
        clearNotes: notes.isEmpty,
        clearVideo: videoUrl.isEmpty,
      );
      final result = await _repository.updateExercise(
        exercise: draft,
        photoBytes: pickedPhotoBytes.value,
        photoFileName: pickedPhotoName.value,
        removePhoto: removeExistingPhoto.value,
      );
      isSaving.value = false;
      if (result.failure != null && result.exercise == null) {
        Get.snackbar('', result.failure!.message.tr,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      _showPhotoWarningIfNeeded(result.failure);
    } else {
      final draft = WorkoutExerciseModel(
        id: '',
        scheduleDayId: args.scheduleDay.id,
        traineeId: args.traineeId,
        trainerId: '',
        name: name,
        sets: sets,
        reps: reps,
        targetWeightKg: weight,
        videoUrl: videoUrl.isEmpty ? null : videoUrl,
        notes: notes.isEmpty ? null : notes,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _repository.createExercise(
        draft: draft,
        scheduleDayId: args.scheduleDay.id,
        traineeId: args.traineeId,
        photoBytes: pickedPhotoBytes.value,
        photoFileName: pickedPhotoName.value,
      );
      isSaving.value = false;
      if (result.failure != null) {
        if (result.exercise != null) {
          _showPhotoWarningIfNeeded(result.failure);
          Get.back(result: true);
          return;
        }
        Get.snackbar('', result.failure!.message.tr,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    Get.back(result: true);
  }

  int? _positiveInt(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  double? _nonNegativeDouble(String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null || value < 0) return null;
    return value;
  }

  void _showPhotoWarningIfNeeded(Failure? failure) {
    if (failure == null) return;
    if (pickedPhotoBytes.value == null) return;
    Get.snackbar('', 'workout_photo_upload_failed'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }
}
