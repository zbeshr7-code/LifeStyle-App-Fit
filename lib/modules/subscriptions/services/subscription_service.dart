import 'package:soccer_sys/core/services/supabase_service.dart';

class SubscriptionService {
  SubscriptionService(this._supabaseService);

  final SupabaseService _supabaseService;

  dynamic get _client => _supabaseService.client;

  Future<List<Map<String, dynamic>>> listTrainerPlans(String trainerId) async {
    final result = await _client.rpc(
      'list_trainer_subscription_plans',
      params: {'p_trainer_id': trainerId},
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>> upsertPlan({
    String? planId,
    required String title,
    String? description,
    required double priceAmount,
    required int durationDays,
    required List<String> features,
    bool isFeatured = false,
    int sortOrder = 0,
  }) async {
    final result = await _client.rpc(
      'upsert_subscription_plan',
      params: {
        'p_plan_id': planId,
        'p_title': title,
        'p_description': description,
        'p_price_amount': priceAmount,
        'p_duration_days': durationDays,
        'p_features': features,
        'p_is_featured': isFeatured,
        'p_sort_order': sortOrder,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> deactivatePlan(String planId) async {
    final result = await _client.rpc(
      'deactivate_subscription_plan',
      params: {'p_plan_id': planId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> subscribeToPlan(String planId) async {
    final result = await _client.rpc(
      'subscribe_to_plan',
      params: {'p_plan_id': planId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> getMyActiveSubscription() async {
    final result = await _client.rpc('get_my_active_subscription');
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> trainerListSubscribers() async {
    final result = await _client.rpc('trainer_list_subscribers');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>?> trainerSubscriptionRevenue({
    DateTime? from,
    DateTime? toExclusive,
  }) async {
    final result = await _client.rpc(
      'trainer_subscription_revenue',
      params: {
        'p_from': from?.toUtc().toIso8601String(),
        'p_to': toExclusive?.toUtc().toIso8601String(),
      },
    );
    if (result == null) return null;
    final list = result as List;
    if (list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first as Map);
  }

  Future<Map<String, dynamic>> trainerUpdateSubscriptionPeriod({
    required String subscriptionId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final result = await _client.rpc(
      'trainer_update_subscription_period',
      params: {
        'p_subscription_id': subscriptionId,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt.toUtc().toIso8601String(),
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> trainerAssignSubscription({
    required String traineeId,
    required String planId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final result = await _client.rpc(
      'trainer_assign_subscription',
      params: {
        'p_trainee_id': traineeId,
        'p_plan_id': planId,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt.toUtc().toIso8601String(),
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> trainerCancelSubscription(
    String subscriptionId,
  ) async {
    final result = await _client.rpc(
      'trainer_cancel_subscription',
      params: {'p_subscription_id': subscriptionId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> initiatePlanPayment(String planId) async {
    final result = await _client.rpc(
      'initiate_plan_payment',
      params: {'p_plan_id': planId},
    );
    final rows = List<Map<String, dynamic>>.from(result as List);
    if (rows.isEmpty) {
      throw Exception('No payment session returned');
    }
    return rows.first;
  }

  Future<Map<String, dynamic>> verifyStorePurchase({
    required String subscriptionId,
    required String productId,
    required String transactionId,
    required String platform,
    String? purchaseToken,
    String? verificationData,
  }) async {
    final response = await _client.functions.invoke(
      'verify-store-purchase',
      body: {
        'subscriptionId': subscriptionId,
        'productId': productId,
        'transactionId': transactionId,
        'platform': platform,
        if (purchaseToken != null) 'purchaseToken': purchaseToken,
        if (verificationData != null) 'verificationData': verificationData,
      },
    );

    final data = response.data;
    if (response.status != 200 || data is! Map<String, dynamic>) {
      final message = data is Map
          ? (data['error'] as String? ?? 'Payment verification failed')
          : 'Payment verification failed';
      throw Exception(message);
    }
    return data;
  }
}
