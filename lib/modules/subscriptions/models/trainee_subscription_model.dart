import 'package:soccer_sys/modules/subscriptions/models/subscription_enums.dart';

class TraineeSubscriptionModel {
  const TraineeSubscriptionModel({
    required this.id,
    required this.traineeId,
    required this.trainerId,
    required this.planTitle,
    required this.planPrice,
    required this.durationDays,
    required this.status,
    required this.paymentStatus,
    required this.startsAt,
    required this.endsAt,
    this.planId,
  });

  final String id;
  final String traineeId;
  final String trainerId;
  final String? planId;
  final String planTitle;
  final double planPrice;
  final int durationDays;
  final SubscriptionStatus status;
  final SubscriptionPaymentStatus paymentStatus;
  final DateTime startsAt;
  final DateTime endsAt;

  bool get isActive =>
      status == SubscriptionStatus.active && endsAt.isAfter(DateTime.now());

  factory TraineeSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return TraineeSubscriptionModel(
      id: json['id'] as String,
      traineeId: json['trainee_id'] as String,
      trainerId: json['trainer_id'] as String,
      planId: json['plan_id'] as String?,
      planTitle: json['plan_title'] as String,
      planPrice: _toDouble(json['plan_price']) ?? 0,
      durationDays: (json['duration_days'] as num).toInt(),
      status: SubscriptionStatus.fromString(json['status'] as String?),
      paymentStatus: SubscriptionPaymentStatus.fromString(
        json['payment_status'] as String?,
      ),
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class TrainerSubscriberModel {
  const TrainerSubscriberModel({
    required this.subscriptionId,
    required this.traineeId,
    required this.firstName,
    required this.lastName,
    required this.planTitle,
    required this.planPrice,
    required this.status,
    required this.paymentStatus,
    required this.startsAt,
    required this.endsAt,
    this.avatarUrl,
  });

  final String subscriptionId;
  final String traineeId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String planTitle;
  final double planPrice;
  final SubscriptionStatus status;
  final SubscriptionPaymentStatus paymentStatus;
  final DateTime startsAt;
  final DateTime endsAt;

  String get fullName => '$firstName $lastName'.trim();

  bool get isActive =>
      status == SubscriptionStatus.active && endsAt.isAfter(DateTime.now());

  factory TrainerSubscriberModel.fromJson(Map<String, dynamic> json) {
    return TrainerSubscriberModel(
      subscriptionId: json['subscription_id'] as String,
      traineeId: json['trainee_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      planTitle: json['plan_title'] as String,
      planPrice: _toDouble(json['plan_price']) ?? 0,
      status: SubscriptionStatus.fromString(json['status'] as String?),
      paymentStatus: SubscriptionPaymentStatus.fromString(
        json['payment_status'] as String?,
      ),
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
