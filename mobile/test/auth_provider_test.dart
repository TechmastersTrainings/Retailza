import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retailza/providers/auth_provider.dart';
import 'package:retailza/models/shop_model.dart';
import 'package:retailza/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Token Persistence via ApiClient', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial token is null when nothing is persisted', () async {
      final token = await ApiClient.getToken();
      expect(token, isNull);
    });

    test('saveTokens persists access and refresh tokens to storage', () async {
      const accessToken = 'jwt_test_access_token_12345';
      const refreshToken = 'jwt_test_refresh_token_67890';

      await ApiClient.saveTokens(accessToken, refreshToken);

      final retrievedToken = await ApiClient.getToken();
      expect(retrievedToken, accessToken);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ApiClient.tokenKey), accessToken);
      expect(prefs.getString(ApiClient.refreshTokenKey), refreshToken);
    });

    test('clearTokens removes all auth tokens from storage', () async {
      await ApiClient.saveTokens('token_a', 'token_b');
      expect(await ApiClient.getToken(), 'token_a');

      await ApiClient.clearTokens();
      expect(await ApiClient.getToken(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ApiClient.tokenKey), isNull);
      expect(prefs.getString(ApiClient.refreshTokenKey), isNull);
    });
  });

  group('Phone and Email Identifier Validation', () {
    String? validateIdentifier(String? val) {
      if (val == null || val.trim().isEmpty) {
        return "Please enter mobile number or email address";
      }
      final trimmed = val.trim();
      if (trimmed.contains('@')) {
        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
        if (!emailRegex.hasMatch(trimmed)) {
          return "Enter a valid email address";
        }
        return null;
      }
      final cleaned = trimmed.replaceAll(RegExp(r'\D'), '');
      if (cleaned.length != 10) {
        return "Enter a valid 10-digit mobile number or email";
      }
      return null;
    }

    test('Rejects null and empty strings', () {
      expect(validateIdentifier(null), isNotNull);
      expect(validateIdentifier(''), isNotNull);
      expect(validateIdentifier('   '), isNotNull);
    });

    test('Accepts valid 10-digit Indian phone numbers', () {
      expect(validateIdentifier('9876543210'), isNull);
      expect(validateIdentifier('7001234567'), isNull);
      expect(validateIdentifier('9123456789'), isNull);
    });

    test('Rejects invalid phone numbers', () {
      expect(validateIdentifier('12345'), isNotNull);
      expect(validateIdentifier('9876543210123'), isNotNull);
      expect(validateIdentifier('abcdefghij'), isNotNull);
    });

    test('Accepts valid email formats', () {
      expect(validateIdentifier('merchant@retailza.com'), isNull);
      expect(validateIdentifier('kirana.store@gmail.com'), isNull);
    });

    test('Rejects malformed email addresses', () {
      expect(validateIdentifier('merchant@'), isNotNull);
      expect(validateIdentifier('merchant@domain'), isNotNull);
      expect(validateIdentifier('@retailza.com'), isNotNull);
    });
  });

  group('AuthProvider State & Logout Lifecycle', () {
    late AuthProvider authProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider();
    });

    test('Initial AuthProvider state is unauthenticated and clear', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.user, isNull);
      expect(authProvider.shop, isNull);
      expect(authProvider.errorMessage, isNull);
    });

    test('clearError resets errorMessage', () {
      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });

    test('setShop updates the shop model and notifies listeners', () {
      final testShop = ShopModel(
        id: 101,
        ownerId: 5,
        shopName: 'Shri Balaji Supermart',
        ownerName: 'Balaji Rao',
        city: 'Bengaluru',
      );

      bool notified = false;
      authProvider.addListener(() {
        notified = true;
      });

      authProvider.setShop(testShop);

      expect(authProvider.shop, isNotNull);
      expect(authProvider.shop?.shopName, 'Shri Balaji Supermart');
      expect(notified, true);
    });

    test('logout clears user, shop, and isAuthenticated state', () async {
      // Mock existing token in storage
      await ApiClient.saveTokens('active_session_token', 'refresh_token');

      // Call logout
      await authProvider.logout();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
      expect(authProvider.shop, isNull);

      // Verify tokens were also wiped from disk
      final tokenAfterLogout = await ApiClient.getToken();
      expect(tokenAfterLogout, isNull);
    });
  });
}
