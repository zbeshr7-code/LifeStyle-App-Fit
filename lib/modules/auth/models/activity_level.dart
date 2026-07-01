enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive;

  String get value {
    return switch (this) {
      ActivityLevel.veryActive => 'very_active',
      _ => name,
    };
  }

  static ActivityLevel? fromString(String? value) {
    if (value == null) return null;
    return ActivityLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => ActivityLevel.moderate,
    );
  }
}
