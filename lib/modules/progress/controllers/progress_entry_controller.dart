import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/progress/repositories/progress_repository.dart';

class ProgressEntryController extends GetxController {
  ProgressEntryController(this._repository, this._authController);

  final ProgressRepository _repository;
  final AuthController _authController;

  final formKey = GlobalKey<FormState>();
  final noteController = TextEditingController();
  final weightController = TextEditingController();
  final recordedAt = Rx<DateTime>(DateTime.now());
  final pickedPhotos = <({Uint8List bytes, String fileName})>[].obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final weight = _authController.currentUser.value?.currentWeight;
    if (weight != null) {
      weightController.text = weight.toString();
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    weightController.dispose();
    super.onClose();
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: recordedAt.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) recordedAt.value = picked;
  }

  Future<void> pickPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    for (final file in files) {
      pickedPhotos.add((
        bytes: await file.readAsBytes(),
        fileName: file.name,
      ));
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < pickedPhotos.length) {
      pickedPhotos.removeAt(index);
    }
  }

  Future<void> save() async {
    if (pickedPhotos.isEmpty) {
      Get.snackbar('', 'progress_photos_required'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSaving.value = true;
    final weight = double.tryParse(weightController.text.trim());
    final result = await _repository.createEntryWithPhotos(
      recordedAt: recordedAt.value,
      weightKg: weight,
      note: _nullableText(noteController.text),
      photos: pickedPhotos.toList(),
    );
    isSaving.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.back();
    Get.snackbar('', 'progress_save_success'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  String? _nullableText(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
