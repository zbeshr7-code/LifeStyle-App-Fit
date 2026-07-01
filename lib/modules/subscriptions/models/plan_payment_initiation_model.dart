class PlanPaymentInitiationModel {
  const PlanPaymentInitiationModel({
    required this.subscriptionId,
    required this.amountHalalas,
    required this.planTitle,
    required this.currency,
  });

  final String subscriptionId;
  final int amountHalalas;
  final String planTitle;
  final String currency;

  bool get isFree => amountHalalas <= 0;

  factory PlanPaymentInitiationModel.fromJson(Map<String, dynamic> json) {
    return PlanPaymentInitiationModel(
      subscriptionId: json['subscription_id'] as String,
      amountHalalas: (json['amount_halalas'] as num).toInt(),
      planTitle: json['plan_title'] as String,
      currency: json['currency'] as String? ?? 'SAR',
    );
  }
}
