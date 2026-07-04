import 'package:soccer_sys/modules/auth/models/activity_level.dart';
import 'package:soccer_sys/modules/auth/models/gender.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isVerified,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.dateOfBirth,
    this.gender,
    this.specialization,
    this.yearsOfExperience,
    this.certification,
    this.hourlyRate,
    this.fitnessGoal,
    this.currentWeight,
    this.targetWeight,
    this.heightCm,
    this.activityLevel,
    this.dailyStepGoal = 10000,
    this.trainerId,
    this.deletedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final UserRole role;
  final String? specialization;
  final int? yearsOfExperience;
  final String? certification;
  final double? hourlyRate;
  final String? fitnessGoal;
  final double? currentWeight;
  final double? targetWeight;
  final double? heightCm;
  final ActivityLevel? activityLevel;
  final int dailyStepGoal;
  final String? trainerId;
  final bool isActive;
  final bool isVerified;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  bool get isTrainer => role == UserRole.trainer;
  bool get isTrainee => role == UserRole.trainee;

  bool get hasTrainer => trainerId != null && trainerId!.isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: (json['email'] as String?) ?? '',
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      gender: Gender.fromString(json['gender'] as String?),
      role: UserRole.fromString(json['role'] as String),
      specialization: json['specialization'] as String?,
      yearsOfExperience: json['years_of_experience'] as int?,
      certification: json['certification'] as String?,
      hourlyRate: _toDouble(json['hourly_rate']),
      fitnessGoal: json['fitness_goal'] as String?,
      currentWeight: _toDouble(json['current_weight']),
      targetWeight: _toDouble(json['target_weight']),
      heightCm: _toDouble(json['height_cm']),
      activityLevel: ActivityLevel.fromString(json['activity_level'] as String?),
      dailyStepGoal: (json['daily_step_goal'] as num?)?.toInt() ?? 10000,
      trainerId: json['trainer_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender?.name,
      'role': role.value,
      'specialization': specialization,
      'years_of_experience': yearsOfExperience,
      'certification': certification,
      'hourly_rate': hourlyRate,
      'fitness_goal': fitnessGoal,
      'current_weight': currentWeight,
      'target_weight': targetWeight,
      'height_cm': heightCm,
      'activity_level': activityLevel?.value,
      'daily_step_goal': dailyStepGoal,
      'trainer_id': trainerId,
      'is_active': isActive,
      'is_verified': isVerified,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    Gender? gender,
    UserRole? role,
    String? specialization,
    int? yearsOfExperience,
    String? certification,
    double? hourlyRate,
    String? fitnessGoal,
    double? currentWeight,
    double? targetWeight,
    double? heightCm,
    ActivityLevel? activityLevel,
    int? dailyStepGoal,
    String? trainerId,
    bool? isActive,
    bool? isVerified,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      certification: certification ?? this.certification,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      trainerId: trainerId ?? this.trainerId,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
