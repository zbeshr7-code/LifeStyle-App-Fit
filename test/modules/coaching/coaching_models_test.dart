import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';

void main() {
  test('UserModel parses trainer_id', () {
    final user = UserModel.fromJson({
      'id': 'u1',
      'first_name': 'Ali',
      'last_name': 'Trainee',
      'email': 'ali@test.com',
      'role': 'trainee',
      'trainer_id': 'trainer-1',
      'is_active': true,
      'is_verified': false,
      'is_deleted': false,
      'created_at': '2026-06-04T10:00:00Z',
      'updated_at': '2026-06-04T10:00:00Z',
    });

    expect(user.trainerId, 'trainer-1');
    expect(user.hasTrainer, isTrue);
    expect(user.role, UserRole.trainee);
  });

  test('UserModel hasTrainer is false when trainer_id missing', () {
    final user = UserModel.fromJson({
      'id': 'u2',
      'first_name': 'Sara',
      'last_name': 'Trainee',
      'email': 'sara@test.com',
      'role': 'trainee',
      'is_active': true,
      'is_verified': false,
      'is_deleted': false,
      'created_at': '2026-06-04T10:00:00Z',
      'updated_at': '2026-06-04T10:00:00Z',
    });

    expect(user.trainerId, isNull);
    expect(user.hasTrainer, isFalse);
  });
}
