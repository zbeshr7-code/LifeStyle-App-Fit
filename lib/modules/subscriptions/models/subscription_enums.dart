enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  pending;

  String get value => name;

  static SubscriptionStatus fromString(String? value) => switch (value) {
        'active' => SubscriptionStatus.active,
        'expired' => SubscriptionStatus.expired,
        'cancelled' => SubscriptionStatus.cancelled,
        'pending' => SubscriptionStatus.pending,
        _ => SubscriptionStatus.expired,
      };
}

enum SubscriptionPaymentStatus {
  waived,
  pendingMoyasar,
  paid;

  String get dbValue => switch (this) {
        SubscriptionPaymentStatus.waived => 'waived',
        SubscriptionPaymentStatus.pendingMoyasar => 'pending_moyasar',
        SubscriptionPaymentStatus.paid => 'paid',
      };

  static SubscriptionPaymentStatus fromString(String? value) => switch (value) {
        'waived' => SubscriptionPaymentStatus.waived,
        'pending_moyasar' => SubscriptionPaymentStatus.pendingMoyasar,
        'paid' => SubscriptionPaymentStatus.paid,
        _ => SubscriptionPaymentStatus.waived,
      };
}

enum PlanDurationPreset {
  oneMonth(30),
  threeMonths(90),
  custom(0);

  const PlanDurationPreset(this.days);
  final int days;
}
