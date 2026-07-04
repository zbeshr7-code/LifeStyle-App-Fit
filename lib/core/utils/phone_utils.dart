import 'package:flutter/services.dart';

abstract final class PhoneUtils {
  static const ksaDialCode = '+966';
  static const ksaLocalPrefix = '05';
  static const ksaLocalLength = 10;
  static const ksaLocalPattern = r'^05\d{8}$';

  /// Converts local Saudi input `05xxxxxxxx` to E.164 `+9665xxxxxxxx`.
  static String? normalizeLocal(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(ksaLocalPattern).hasMatch(digits)) return null;
    return '$ksaDialCode${digits.substring(1)}';
  }

  static bool isValidSaudiMobile(String input) => normalizeLocal(input) != null;

  static String mask(String e164) {
    if (e164.length < 8) return e164;
    return '${e164.substring(0, 4)} *** **${e164.substring(e164.length - 2)}';
  }
}

class SaudiPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (!digits.startsWith('0')) {
      digits = digits.startsWith('5') ? '0$digits' : '05$digits';
    }

    if (digits.length >= 2 && digits[1] != '5') {
      digits = '05${digits.substring(2)}';
    }

    if (digits.length > PhoneUtils.ksaLocalLength) {
      digits = digits.substring(0, PhoneUtils.ksaLocalLength);
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
