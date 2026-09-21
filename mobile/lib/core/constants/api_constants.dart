import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static const String defaultPort = "8000";
  static const String serverUrlPrefKey = "retailza_server_base_url_v2";

  // Production Render Cloud API (works anywhere on 4G/5G/Wi-Fi)
  static const String defaultCloudUrl = "https://retailza-api.onrender.com/api";

  // Local development fallbacks
  static const String defaultWifiIp = "192.168.1.7";
  static const String emulatorIp = "10.0.2.2";

  static String get defaultHost {
    if (kIsWeb) return "127.0.0.1";
    return defaultWifiIp;
  }

  // Live Cloud backend is now default for all devices
  static String baseUrl = defaultCloudUrl;

  static Future<void> loadSavedBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(serverUrlPrefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        baseUrl = saved.trim();
      } else {
        baseUrl = defaultCloudUrl;
      }
    } catch (_) {
      baseUrl = defaultCloudUrl;
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    baseUrl = newUrl.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(serverUrlPrefKey, baseUrl);
    } catch (_) {}
  }

  // Auth endpoints
  static const String requestOtp = "/auth/request-otp";
  static const String verifyOtp = "/auth/verify-otp";
  static const String loginPassword = "/auth/login-password";
  static const String refreshToken = "/auth/refresh-token";
  static const String me = "/auth/me";

  // Shop endpoints
  static const String shopSetup = "/shops/setup";
  static const String currentShop = "/shops/current";

  // Subscription endpoints
  static const String currentSubscription = "/subscriptions/current";
  static const String createSubscriptionOrder = "/subscriptions/create-order";
  static const String verifySubscriptionPayment = "/subscriptions/verify-payment";

  // Products & Catalog
  static const String products = "/products";
  static const String barcodeSearch = "/products/barcode";

  // Inventory & Stock
  static const String inventory = "/inventory";

  // Sales & Billing POS
  static const String checkout = "/sales/checkout";
  static const String sales = "/sales";

  // Khata & Customers
  static const String customers = "/customers";

  // Dashboard
  static const String dashboardMetrics = "/dashboard/metrics";

  // Announcements & Feature Pushes
  static const String latestAnnouncement = "/announcements/latest";
}
