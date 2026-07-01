class ProgressPhotoModel {
  const ProgressPhotoModel({
    required this.id,
    required this.entryId,
    required this.storagePath,
    required this.sortOrder,
    required this.createdAt,
    this.resolvedUrl,
  });

  final String id;
  final String entryId;
  final String storagePath;
  final int sortOrder;
  final DateTime createdAt;
  final String? resolvedUrl;

  ProgressPhotoModel copyWith({String? resolvedUrl}) {
    return ProgressPhotoModel(
      id: id,
      entryId: entryId,
      storagePath: storagePath,
      sortOrder: sortOrder,
      createdAt: createdAt,
      resolvedUrl: resolvedUrl ?? this.resolvedUrl,
    );
  }

  factory ProgressPhotoModel.fromJson(Map<String, dynamic> json) {
    return ProgressPhotoModel(
      id: json['id'] as String,
      entryId: json['entry_id'] as String,
      storagePath: json['storage_path'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
