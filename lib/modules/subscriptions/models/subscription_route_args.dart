import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';

class SubscriptionCheckoutArgs {
  const SubscriptionCheckoutArgs({required this.plan});

  final SubscriptionPlanModel plan;
}

class TrainerPlanFormArgs {
  const TrainerPlanFormArgs({this.plan});

  final SubscriptionPlanModel? plan;
}

class TrainerSubscriptionEditArgs {
  const TrainerSubscriptionEditArgs({required this.subscriber});

  final TrainerSubscriberModel subscriber;
}
