abstract final class NameParser {
  static ({String firstName, String lastName}) split(String fullName) {
    final trimmed = fullName.trim();
    final spaceIndex = trimmed.indexOf(' ');

    if (spaceIndex == -1) {
      return (firstName: trimmed, lastName: '');
    }

    return (
      firstName: trimmed.substring(0, spaceIndex),
      lastName: trimmed.substring(spaceIndex + 1).trim(),
    );
  }
}

