enum NutritionDayType {
  workout,
  rest;

  String get value => name;

  static NutritionDayType fromString(String? value) {
    return NutritionDayType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NutritionDayType.workout,
    );
  }
}

class NutritionMealModel {
  const NutritionMealModel({
    required this.id,
    required this.traineeId,
    required this.trainerId,
    required this.dayType,
    required this.title,
    required this.foodItems,
    required this.calories,
    this.notes,
    this.photoPath,
    this.photoUrl,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String traineeId;
  final String trainerId;
  final NutritionDayType dayType;
  final String title;
  final String foodItems;
  final int calories;
  final String? notes;
  final String? photoPath;
  final String? photoUrl;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<String> get foodItemLines => foodItems
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  int get totalCalories => calories;

  NutritionMealModel copyWith({
    String? id,
    String? traineeId,
    String? trainerId,
    NutritionDayType? dayType,
    String? title,
    String? foodItems,
    int? calories,
    String? notes,
    String? photoPath,
    String? photoUrl,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearNotes = false,
    bool clearPhoto = false,
  }) {
    return NutritionMealModel(
      id: id ?? this.id,
      traineeId: traineeId ?? this.traineeId,
      trainerId: trainerId ?? this.trainerId,
      dayType: dayType ?? this.dayType,
      title: title ?? this.title,
      foodItems: foodItems ?? this.foodItems,
      calories: calories ?? this.calories,
      notes: clearNotes ? null : (notes ?? this.notes),
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NutritionMealModel.fromJson(Map<String, dynamic> json) {
    return NutritionMealModel(
      id: json['id'] as String,
      traineeId: json['trainee_id'] as String,
      trainerId: json['trainer_id'] as String,
      dayType: NutritionDayType.fromString(json['day_type'] as String?),
      title: json['title'] as String,
      foodItems: json['food_items'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      photoPath: json['photo_path'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson({
    required String traineeId,
    required String trainerId,
    required NutritionDayType dayType,
    required int sortOrder,
  }) {
    return {
      'trainee_id': traineeId,
      'trainer_id': trainerId,
      'day_type': dayType.value,
      'title': title,
      'food_items': foodItems,
      'calories': calories,
      'notes': notes,
      'photo_path': photoPath,
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'food_items': foodItems,
      'calories': calories,
      'notes': notes,
      'photo_path': photoPath,
      'day_type': dayType.value,
    };
  }
}

class MealFormArgs {
  const MealFormArgs({
    required this.traineeId,
    required this.dayType,
    this.meal,
  });

  final String traineeId;
  final NutritionDayType dayType;
  final NutritionMealModel? meal;

  bool get isEditing => meal != null;
}
