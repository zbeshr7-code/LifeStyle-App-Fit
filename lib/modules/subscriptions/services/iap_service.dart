import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  IapService() : _iap = InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<bool> isStoreAvailable() async {
    if (kIsWeb) return false;
    return _iap.isAvailable();
  }

  Future<ProductDetails?> queryProduct(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.error != null || response.productDetails.isEmpty) {
      return null;
    }
    return response.productDetails.firstWhere(
      (p) => p.id == productId,
      orElse: () => response.productDetails.first,
    );
  }

  void listenPurchases(void Function(PurchaseDetails purchase) onUpdate) {
    _purchaseSub?.cancel();
    _purchaseSub = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        onUpdate(purchase);
      }
    });
  }

  Future<bool> buy(ProductDetails product) {
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
  }

  static String platformLabel() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'unknown',
    };
  }
}
