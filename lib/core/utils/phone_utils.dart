abstract final class PhoneUtils {
  static const defaultCountryCode = '+966';

  /// Normalizes Saudi mobile input to E.164 (+9665xxxxxxxx).
  static String? normalize(
    String input, {
    String countryCode = defaultCountryCode,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (trimmed.startsWith('+')) {
      return '+$digits';
    }

    if (digits.startsWith('966') && digits.length >= 12) {
      return '+$digits';
    }

    if (digits.startsWith('0') && digits.length == 10) {
      digits = digits.substring(1);
    }

    if (digits.length == 9 && digits.startsWith('5')) {
      return '$countryCode$digits';
    }

    return null;
  }

  static bool isValidSaudiMobile(String input) {
    final normalized = normalize(input);
    if (normalized == null) return false;
    return RegExp(r'^\+9665\d{8}$').hasMatch(normalized);
  }

  static String mask(String e164) {
    if (e164.length < 8) return e164;
    return '${e164.substring(0, 4)} *** **${e164.substring(e164.length - 2)}';
  }
}
