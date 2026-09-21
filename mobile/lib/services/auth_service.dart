import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class AuthService {
  Future<Map<String, dynamic>> requestOtp(String identifier) async {
    final response = await ApiClient.post(
      ApiConstants.requestOtp,
      body: {
        'identifier': identifier,
        'mobile_number': identifier,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(String identifier, String otpCode) async {
    final response = await ApiClient.post(
      ApiConstants.verifyOtp,
      body: {
        'identifier': identifier,
        'mobile_number': identifier,
        'otp_code': otpCode,
      },
    );

    final data = response as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;
    await ApiClient.saveTokens(accessToken, refreshToken);

    return data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await ApiClient.get(ApiConstants.me);
    return response as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await ApiClient.clearTokens();
  }
}
