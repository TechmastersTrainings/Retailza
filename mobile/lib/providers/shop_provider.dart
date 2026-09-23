import 'package:flutter/material.dart';
import '../models/shop_model.dart';
import '../models/subscription_model.dart';
import '../services/shop_service.dart';
import '../services/subscription_service.dart';
import '../core/network/api_client.dart';

class ShopProvider extends ChangeNotifier {
  final ShopService _shopService = ShopService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = false;
  ShopModel? _shop;
  SubscriptionModel? _subscription;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  ShopModel? get shop => _shop;
  SubscriptionModel? get subscription => _subscription;
  String? get errorMessage => _errorMessage;

  bool get isSubscriptionActive => _subscription != null && _subscription!.isActive;

  Future<void> loadShopData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Immediately restore cached shop and subscription if available
    try {
      final cachedShop = await ApiClient.getCachedShop();
      if (cachedShop != null && _shop == null) {
        _shop = ShopModel.fromJson(cachedShop);
      }
      final cachedSub = await ApiClient.getCachedSubscription();
      if (cachedSub != null && _subscription == null) {
        _subscription = SubscriptionModel.fromJson(cachedSub);
      }
      if (_shop != null || _subscription != null) {
        notifyListeners();
      }
    } catch (_) {}

    try {
      _shop = await _shopService.getCurrentShop();
      await loadSubscription();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setupShop({
    required String shopName,
    required String ownerName,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? upiQrImage,
    String? upiId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shop = await _shopService.setupShop(
        shopName: shopName,
        ownerName: ownerName,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        upiQrImage: upiQrImage,
        upiId: upiId,
      );
      await loadSubscription();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateShop({
    String? shopName,
    String? ownerName,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? upiQrImage,
    String? upiId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shop = await _shopService.updateShop(
        shopName: shopName,
        ownerName: ownerName,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        upiQrImage: upiQrImage,
        upiId: upiId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUpiQr({String? upiQrImage, String? upiId}) async {
    return await updateShop(upiQrImage: upiQrImage, upiId: upiId);
  }

  Future<void> loadSubscription() async {
    try {
      _subscription = await _subscriptionService.getCurrentSubscription();
      notifyListeners();
    } catch (_) {
      if (_subscription == null) {
        final cached = await ApiClient.getCachedSubscription();
        if (cached != null) {
          _subscription = SubscriptionModel.fromJson(cached);
          notifyListeners();
        }
      }
    }
  }

  Future<Map<String, dynamic>> createSubscriptionOrder() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _subscriptionService.createOrder();
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> verifySubscriptionPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = await _subscriptionService.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeMockPayment() async {
    _isLoading = true;
    notifyListeners();

    try {
      final order = await _subscriptionService.createOrder();
      final orderId = order['order_id'] as String;

      _subscription = await _subscriptionService.verifyPayment(
        orderId: orderId,
        paymentId: "pay_test_kirana_live",
        signature: "mock_valid_signature",
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
