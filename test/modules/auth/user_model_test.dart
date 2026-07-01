import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/auth/models/activity_level.dart';
import 'package:soccer_sys/modules/auth/models/gender.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';

void main() {
  final baseUser = UserModel(
    id: 'u1',
    firstName: 'Ali',
    lastName: 'Hassan',
    email: 'ali@test.com',
    role: UserRole.trainee,
    isActive: true,
    isVerified: false,
    isDeleted: false,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
    gender: Gender.male,
    activityLevel: ActivityLevel.moderate,
    dailyStepGoal: 8000,
  );

  test('UserModel.copyWith updates selected fields', () {
    final updated = baseUser.copyWith(
      firstName: 'Omar',
      dailyStepGoal: 12000,
    );

    expect(updated.firstName, 'Omar');
    expect(updated.lastName, baseUser.lastName);
    expect(updated.dailyStepGoal, 12000);
  });

  test('UserModel.fromJson round-trip preserves daily step goal', () {
    final json = baseUser.toJson();
    final parsed = UserModel.fromJson(json);

    expect(parsed.dailyStepGoal, 8000);
    expect(parsed.fullName, 'Ali Hassan');
  });
}
