import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends GetxController {
  static const prefKey = 'app_locale';

  final locale = const Locale('ar').obs;

  bool get isRtl => locale.value.languageCode == 'ar';

  String get currentLanguageLabel =>
      locale.value.languageCode == 'ar' ? 'language_ar'.tr : 'language_en'.tr;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(prefKey);
    final saved = code == 'en' || code == 'ar' ? Locale(code!) : const Locale('ar');
    await _applyLocale(saved, persist: false);
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode == locale.value.languageCode) return;
    await _applyLocale(Locale(languageCode), persist: true);
  }

  Future<void> _applyLocale(Locale value, {required bool persist}) async {
    locale.value = value;
    Get.updateLocale(value);
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, value.languageCode);
    }
  }
}
