import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../services/auth_service.dart';

import '../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  UserModel? _user;
  ShopModel? _shop;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get user => _user;
  ShopModel? get shop => _shop;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await ApiClient.getToken();
      if (token == null || token.isEmpty) {
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check cached user and shop first for instant launch
      final cachedUser = await ApiClient.getCachedUser();
      if (cachedUser != null) {
        _user = UserModel.fromJson(cachedUser);
        final cachedShop = await ApiClient.getCachedShop();
        if (cachedShop != null) {
          _shop = ShopModel.fromJson(cachedShop);
        }
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        // Refresh in background without blocking or resetting auth on network delay
        _silentRefresh();
        return true;
      }

      // If no cached user, perform full network fetch
      final data = await _authService.getMe();
      if (data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
        if (data['shop'] != null) {
          _shop = ShopModel.fromJson(data['shop']);
        }
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains("401") || msg.contains("unauthorized")) {
        await logout();
      }
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void _silentRefresh() async {
    try {
      final data = await _authService.getMe();
      if (data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
        if (data['shop'] != null) {
          _shop = ShopModel.fromJson(data['shop']);
        }
        notifyListeners();
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains("401") || msg.contains("unauthorized")) {
        await logout();
      }
    }
  }

  Future<String?> requestOtp(String identifier) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.requestOtp(identifier);
      _isLoading = false;
      notifyListeners();
      return res['debug_otp'] as String?;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyOtp(String identifier, String otpCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.verifyOtp(identifier, otpCode);
      _user = UserModel.fromJson(res['user']);
      if (res['shop'] != null) {
        _shop = ShopModel.fromJson(res['shop']);
      }
      _isAuthenticated = true;
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

  void setShop(ShopModel newShop) {
    _shop = newShop;
    ApiClient.saveCachedShop(newShop.toJson());
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    _shop = null;
    notifyListeners();
  }
}
