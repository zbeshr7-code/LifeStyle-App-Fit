class PhoneCountry {
  const PhoneCountry({
    required this.code,
    required this.dialCode,
    required this.nameKey,
    required this.flag,
  });

  final String code;
  final String dialCode;
  final String nameKey;
  final String flag;

  static const ksa = PhoneCountry(
    code: 'SA',
    dialCode: '+966',
    nameKey: 'country_ksa',
    flag: '🇸🇦',
  );

  static const List<PhoneCountry> supported = [ksa];
}
