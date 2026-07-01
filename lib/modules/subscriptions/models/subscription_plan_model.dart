class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.priceAmount,
    required this.durationDays,
    required this.features,
    required this.isActive,
    required this.isFeatured,
    required this.sortOrder,
    this.description,
    this.currency = 'SAR',
  });

  final String id;
  final String trainerId;
  final String title;
  final String? description;
  final double priceAmount;
  final String currency;
  final int durationDays;
  final List<String> features;
  final bool isActive;
  final bool isFeatured;
  final int sortOrder;

  String get durationLabelKey => switch (durationDays) {
        30 => 'subscription_duration_1_month',
        90 => 'subscription_duration_3_months',
        _ => 'subscription_duration_custom',
      };

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final features = <String>[];
    if (rawFeatures is List) {
      for (final item in rawFeatures) {
        if (item is String && item.trim().isNotEmpty) {
          features.add(item.trim());
        }
      }
    }

    return SubscriptionPlanModel(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priceAmount: _toDouble(json['price_amount']) ?? 0,
      currency: json['currency'] as String? ?? 'SAR',
      durationDays: (json['duration_days'] as num).toInt(),
      features: features,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
