import 'package:soccer_sys/modules/progress/models/progress_photo_model.dart';

class ProgressEntryModel {
  const ProgressEntryModel({
    required this.id,
    required this.userId,
    required this.recordedAt,
    this.weightKg,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.photos = const [],
  });

  final String id;
  final String userId;
  final DateTime recordedAt;
  final double? weightKg;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProgressPhotoModel> photos;

  ProgressPhotoModel? get coverPhoto =>
      photos.isEmpty ? null : photos.first;

  ProgressEntryModel copyWith({
    List<ProgressPhotoModel>? photos,
  }) {
    return ProgressEntryModel(
      id: id,
      userId: userId,
      recordedAt: recordedAt,
      weightKg: weightKg,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photos: photos ?? this.photos,
    );
  }

  factory ProgressEntryModel.fromJson(Map<String, dynamic> json) {

    final photosJson = json['trainee_progress_photos'];
    List<ProgressPhotoModel> photos;
    if (photosJson is List) {
      photos = photosJson
          .map((p) => ProgressPhotoModel.fromJson(
                Map<String, dynamic>.from(p as Map),
              ))
          .toList();
      photos.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } else {
      photos = [];
    }

    return ProgressEntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      weightKg: _toDouble(json['weight_kg']),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      photos: photos,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class ProgressGalleryPhotoItem {
  const ProgressGalleryPhotoItem({
    required this.entry,
    required this.photo,
    required this.photoIndex,
  });

  final ProgressEntryModel entry;
  final ProgressPhotoModel photo;
  final int photoIndex;
}

class ProgressEntryArgs {
  const ProgressEntryArgs({
    required this.entry,
    this.initialPhotoIndex = 0,
  });

  final ProgressEntryModel entry;
  final int initialPhotoIndex;
}
