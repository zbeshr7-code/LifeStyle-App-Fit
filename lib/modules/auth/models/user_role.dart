enum UserRole {
  trainee,
  trainer;

  String get value => name;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.trainee,
    );
  }
}
