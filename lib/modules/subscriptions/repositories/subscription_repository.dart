import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/modules/subscriptions/models/plan_payment_initiation_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainer_subscription_revenue_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';
import 'package:soccer_sys/modules/subscriptions/services/subscription_service.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._service);

  final SubscriptionService _service;

  Future<({Failure? failure, List<SubscriptionPlanModel> plans})>
      listTrainerPlans(String trainerId) async {
    try {
      final data = await _service.listTrainerPlans(trainerId);
      final plans = data.map(SubscriptionPlanModel.fromJson).toList();
      return (failure: null, plans: plans);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        plans: <SubscriptionPlanModel>[],
      );
    }
  }

  Future<({Failure? failure, SubscriptionPlanModel? plan})> upsertPlan({
    String? planId,
    required String title,
    String? description,
    required double priceAmount,
    required int durationDays,
    required List<String> features,
    bool isFeatured = false,
    int sortOrder = 0,
  }) async {
    try {
      final data = await _service.upsertPlan(
        planId: planId,
        title: title,
        description: description,
        priceAmount: priceAmount,
        durationDays: durationDays,
        features: features,
        isFeatured: isFeatured,
        sortOrder: sortOrder,
      );
      return (failure: null, plan: SubscriptionPlanModel.fromJson(data));
    } catch (error) {
      return (failure: FailureMapper.fromException(error), plan: null);
    }
  }

  Future<Failure?> deactivatePlan(String planId) async {
    try {
      await _service.deactivatePlan(planId);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<({Failure? failure, TraineeSubscriptionModel? subscription})>
      subscribeToPlan(String planId) async {
    try {
      final data = await _service.subscribeToPlan(planId);
      return (
        failure: null,
        subscription: TraineeSubscriptionModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), subscription: null);
    }
  }

  Future<({Failure? failure, TraineeSubscriptionModel? subscription})>
      getMyActiveSubscription() async {
    try {
      final data = await _service.getMyActiveSubscription();
      if (data == null) {
        return (failure: null, subscription: null);
      }
      return (
        failure: null,
        subscription: TraineeSubscriptionModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), subscription: null);
    }
  }

  Future<({Failure? failure, TrainerSubscriptionRevenueModel? revenue})>
      trainerSubscriptionRevenue({
    DateTime? from,
    DateTime? toExclusive,
  }) async {
    try {
      final data = await _service.trainerSubscriptionRevenue(
        from: from,
        toExclusive: toExclusive,
      );
      if (data == null) {
        return (
          failure: null,
          revenue: const TrainerSubscriptionRevenueModel(
            totalAmount: 0,
            paidAmount: 0,
            subscriptionCount: 0,
            currency: 'SAR',
          ),
        );
      }
      return (
        failure: null,
        revenue: TrainerSubscriptionRevenueModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), revenue: null);
    }
  }

  Future<({Failure? failure, List<TrainerSubscriberModel> subscribers})>
      trainerListSubscribers() async {
    try {
      final data = await _service.trainerListSubscribers();
      final subscribers =
          data.map(TrainerSubscriberModel.fromJson).toList();
      return (failure: null, subscribers: subscribers);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        subscribers: <TrainerSubscriberModel>[],
      );
    }
  }

  Future<({Failure? failure, TraineeSubscriptionModel? subscription})>
      trainerUpdateSubscriptionPeriod({
    required String subscriptionId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    try {
      final data = await _service.trainerUpdateSubscriptionPeriod(
        subscriptionId: subscriptionId,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      return (
        failure: null,
        subscription: TraineeSubscriptionModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), subscription: null);
    }
  }

  Future<({Failure? failure, TraineeSubscriptionModel? subscription})>
      trainerAssignSubscription({
    required String traineeId,
    required String planId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    try {
      final data = await _service.trainerAssignSubscription(
        traineeId: traineeId,
        planId: planId,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      return (
        failure: null,
        subscription: TraineeSubscriptionModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), subscription: null);
    }
  }

  Future<({Failure? failure, TraineeSubscriptionModel? subscription})>
      trainerCancelSubscription(String subscriptionId) async {
    try {
      final data = await _service.trainerCancelSubscription(subscriptionId);
      return (
        failure: null,
        subscription: TraineeSubscriptionModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), subscription: null);
    }
  }

  Future<({Failure? failure, PlanPaymentInitiationModel? session})>
      initiatePlanPayment(String planId) async {
    try {
      final data = await _service.initiatePlanPayment(planId);
      return (
        failure: null,
        session: PlanPaymentInitiationModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), session: null);
    }
  }

  Future<({Failure? failure, TraineeSubscriptionModel? subscription})>
      verifyStorePurchase({
    required String subscriptionId,
    required String productId,
    required String transactionId,
    required String platform,
    String? purchaseToken,
    String? verificationData,
  }) async {
    try {
      final data = await _service.verifyStorePurchase(
        subscriptionId: subscriptionId,
        productId: productId,
        transactionId: transactionId,
        platform: platform,
        purchaseToken: purchaseToken,
        verificationData: verificationData,
      );
      final subJson = data['subscription'] as Map<String, dynamic>?;
      if (subJson == null) {
        return (
          failure: const ServerFailure('subscription_verify_failed'),
          subscription: null,
        );
      }
      return (
        failure: null,
        subscription: TraineeSubscriptionModel.fromJson(subJson),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), subscription: null);
    }
  }
}
