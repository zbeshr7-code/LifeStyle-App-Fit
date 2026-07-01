enum Gender {
  male,
  female;

  static Gender? fromString(String? value) {
    if (value == null) return null;
    for (final gender in Gender.values) {
      if (gender.name == value) return gender;
    }
    return null;
  }
}
