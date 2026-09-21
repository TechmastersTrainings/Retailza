import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {this.statusCode = 500});

  @override
  String toString() => message;
}

class ApiClient {
  static const String tokenKey = "auth_access_token";
  static const String refreshTokenKey = "auth_refresh_token";

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, accessToken);
    await prefs.setString(refreshTokenKey, refreshToken);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(refreshTokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http.get(uri, headers: await _headers());
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network connection failed: ${e.toString()}");
    }
  }

  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network connection failed: ${e.toString()}");
    }
  }

  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network connection failed: ${e.toString()}");
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");
      final response = await http.delete(uri, headers: await _headers());
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network connection failed: ${e.toString()}");
    }
  }

  static dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    } else {
      String errorMessage = "An error occurred";
      if (jsonBody is Map<String, dynamic> && jsonBody.containsKey("detail")) {
        errorMessage = jsonBody["detail"].toString();
      } else if (response.statusCode == 401) {
        errorMessage = "Session expired. Please log in again.";
      } else if (response.statusCode == 404) {
        errorMessage = "Resource not found.";
      } else if (response.statusCode == 402) {
        errorMessage = "Active ₹49/month subscription required.";
      }
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}
