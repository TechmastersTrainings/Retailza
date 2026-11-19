import 'package:flutter/material.dart';
import '../models/shop_model.dart';
import '../models/subscription_model.dart';
import '../services/shop_service.dart';
import '../services/subscription_service.dart';
export '../services/subscription_service.dart' show SubscriptionPaymentOrder, SubscriptionPaymentStatus;
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

  bool get isSubscriptionActive => _subscription != null && _subscription!.isActive && !_subscription!.computedIsLocked;
  bool get isAppLocked => _subscription != null ? _subscription!.computedIsLocked : false;
  bool get shouldShow14DayReminder => _subscription != null ? _subscription!.shouldShow14DayReminder : false;
  int get subscriptionDaysRemaining => _subscription?.daysRemaining ?? (_subscription?.endDate != null ? _subscription!.endDate!.difference(DateTime.now()).inDays.clamp(0, 30) : 0);

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
    String? category,
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
        category: category,
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
    String? category,
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
        category: category,
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

  /// Creates a UPI Gateway payment order for the subscription fee.
  Future<SubscriptionPaymentOrder> createSubscriptionOrder() async {
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

  /// Asks the backend (which asks the gateway) whether the order is paid.
  /// Returns null on a network error so callers can simply poll again.
  Future<SubscriptionPaymentStatus?> checkSubscriptionPayment(String orderId) async {
    try {
      final result = await _subscriptionService.getPaymentStatus(orderId);
      _subscription = result.subscription;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  /// Submits the 12-digit UPI UTR to immediately verify payment and activate subscription.
  Future<SubscriptionPaymentStatus?> submitSubscriptionUtr(String orderId, String utr) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _subscriptionService.submitUtr(orderId, utr);
      _subscription = result.subscription;
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> completeMockPayment() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subscription = SubscriptionModel(
        id: _subscription?.id ?? 1,
        shopId: _shop?.id ?? 1,
        planName: "basic",
        amount: 49.0,
        status: "ACTIVE",
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        isLocked: false,
        trialDaysCompleted: false,
        daysRemaining: 30,
        daysElapsed: 0,
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
