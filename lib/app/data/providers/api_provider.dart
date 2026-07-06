import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ApiProvider - Centralized API configuration for the app
/// Handles authentication tokens, base URL, and Dio instance
class ApiProvider extends GetxService {
  late Dio _dio;

  // Base URL for the API
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const _authTokenKey = 'token';

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and token handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(_authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          log('📤 REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log(
            '📥 RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          log(
            '❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          log('❌ Message: ${error.message}');
          log('❌ Response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Update auth token
  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  /// Remove auth token (logout)
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    return token != null && token.isNotEmpty;
  }
}
