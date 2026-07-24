import 'package:dio/dio.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/main.dart' as main_app;
import 'package:docwellness/utils/functions/app_error.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Future<Response?> request({
    required String endPoint,
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    // Set to true to suppress the error dialog (e.g. silent background syncs)
    bool silent = false,
  }) async {
    final url = '${AppConfig.patientApiBaseUrl}$endPoint';
    debugPrint("🌐 API Request: $method $url");
    try {
      Response response = await _dio.request(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: headers,
          // Let Dio auto-set multipart/form-data with boundary for FormData
          contentType: data is FormData ? null : 'application/json',
        ),
      );
      debugPrint("✅ Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("❌ Dio Error [${e.type}] ${e.response?.statusCode}");

      // Expired / invalid token — clear session and redirect to login
      if (e.response?.statusCode == 401) {
        _handleUnauthorized();
        return e.response;
      }

      // 4xx / 5xx — return the response so callers can inspect the body
      if (e.response != null) {
        if (!silent && (e.response!.statusCode ?? 0) >= 500) {
          AppError.handle(e);
        }
        return e.response;
      }

      // No response at all — no internet / timeout
      if (!silent) AppError.handle(e);
      return null;
    }
  }

  static bool _redirecting = false;

  static void _handleUnauthorized() async {
    if (_redirecting) return;
    // Still inside _bootstrap() - no navigator exists yet to redirect to,
    // and getUserData() (the only caller reachable this early) already has
    // its own precise handling for a 401 here (refresh-and-retry, or a
    // clean logout if the refresh token itself is dead). Reacting here too
    // would just race it.
    if (!main_app.appStarted) return;
    // No active session means this is just a failed login attempt — don't redirect
    if (main_app.token == null || main_app.token!.isEmpty) return;
    _redirecting = true;
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.clear();
      main_app.token = null;
      main_app.userId = null;
      main_app.role = null;
      Get.offAllNamed(Routes.AUTH);
    } catch (_) {
    } finally {
      _redirecting = false;
    }
  }
}
