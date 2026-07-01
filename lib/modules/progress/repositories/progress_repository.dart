import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/modules/progress/models/progress_entry_model.dart';
import 'package:soccer_sys/modules/progress/models/progress_photo_model.dart';
import 'package:soccer_sys/modules/progress/services/progress_service.dart';
import 'package:soccer_sys/modules/progress/services/progress_storage_service.dart';

class ProgressRepository {
  ProgressRepository(this._progressService, this._storageService);

  final ProgressService _progressService;
  final ProgressStorageService _storageService;

  Future<({Failure? failure, List<ProgressEntryModel> entries})>
      fetchEntriesWithUrls() async {
    try {
      final data = await _progressService.fetchEntries();
      final entries = <ProgressEntryModel>[];
      for (final row in data) {
        var entry = ProgressEntryModel.fromJson(row);
        final photos = <ProgressPhotoModel>[];
        for (final photo in entry.photos) {
          final url = await _storageService.resolveUrl(photo.storagePath);
          photos.add(photo.copyWith(resolvedUrl: url));
        }
        entries.add(entry.copyWith(photos: photos));
      }
      return (failure: null, entries: entries);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), entries: <ProgressEntryModel>[]);
    }
  }

  Future<({Failure? failure, ProgressEntryModel? entry})> createEntryWithPhotos({
    required DateTime recordedAt,
    double? weightKg,
    String? note,
    required List<({Uint8List bytes, String fileName})> photos,
  }) async {
    if (photos.isEmpty) {
      return (
        failure: const ValidationFailure('progress_photos_required'),
        entry: null,
      );
    }

    try {
      final entryData = await _progressService.createEntry(
        recordedAt: recordedAt,
        weightKg: weightKg,
        note: note,
      );
      final entryId = entryData['id'] as String;
      final savedPhotos = <ProgressPhotoModel>[];

      for (var i = 0; i < photos.length; i++) {
        final item = photos[i];
        final photoId = '${DateTime.now().millisecondsSinceEpoch}_$i';
        final path = await _storageService.uploadPhoto(
          entryId: entryId,
          photoId: photoId,
          bytes: item.bytes,
          fileName: item.fileName,
        );
        final photoData = await _progressService.insertPhoto(
          entryId: entryId,
          storagePath: path,
          sortOrder: i,
        );
        final photo = ProgressPhotoModel.fromJson(photoData);
        final url = await _storageService.resolveUrl(path);
        savedPhotos.add(photo.copyWith(resolvedUrl: url));
      }

      final entry = ProgressEntryModel.fromJson(entryData)
          .copyWith(photos: savedPhotos);
      return (failure: null, entry: entry);
    } catch (error) {
      debugPrint('ProgressRepository.createEntryWithPhotos error: $error');
      return (failure: FailureMapper.fromException(error), entry: null);
    }
  }

  Future<Failure?> deleteEntry(ProgressEntryModel entry) async {
    try {
      final paths = entry.photos.map((p) => p.storagePath).toList();
      await _storageService.deletePaths(paths);
      await _progressService.deleteEntry(entry.id);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }
}
