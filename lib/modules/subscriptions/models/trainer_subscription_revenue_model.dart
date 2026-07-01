class TrainerSubscriptionRevenueModel {
  const TrainerSubscriptionRevenueModel({
    required this.totalAmount,
    required this.paidAmount,
    required this.subscriptionCount,
    required this.currency,
  });

  final double totalAmount;
  final double paidAmount;
  final int subscriptionCount;
  final String currency;

  factory TrainerSubscriptionRevenueModel.fromJson(Map<String, dynamic> json) {
    return TrainerSubscriptionRevenueModel(
      totalAmount: _toDouble(json['total_amount']) ?? 0,
      paidAmount: _toDouble(json['paid_amount']) ?? 0,
      subscriptionCount: (json['subscription_count'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'SAR',
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
