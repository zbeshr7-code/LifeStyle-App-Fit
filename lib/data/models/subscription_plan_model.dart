import 'package:get/get.dart';

class SubscriptionPlan {
  final String id;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final double price;
  final int durationDays;
  final List<String> featuresEn;
  final List<String> featuresAr;

  SubscriptionPlan({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    required this.price,
    required this.durationDays,
    required this.featuresEn,
    required this.featuresAr,
  });

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
  String? get description => Get.locale?.languageCode == 'ar' ? descriptionAr : descriptionEn;
  List<String> get features => Get.locale?.languageCode == 'ar' ? featuresAr : featuresEn;

  String get formattedPrice => '${price.toStringAsFixed(0)} ${'sar'.tr}';

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      nameEn: json['name_en'],
      nameAr: json['name_ar'],
      descriptionEn: json['description_en'],
      descriptionAr: json['description_ar'],
      price: double.parse(json['price'].toString()),
      durationDays: json['duration_days'],
      featuresEn: List<String>.from(json['features_en'] ?? []),
      featuresAr: List<String>.from(json['features_ar'] ?? []),
    );
  }
}
