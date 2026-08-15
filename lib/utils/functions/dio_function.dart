import 'package:dio/dio.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/core/session/session_service.dart';
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

  /// Proactively refreshes the access token before it expires, replacing
  /// the Supabase SDK's own background auto-refresh timer (removed
  /// alongside every other direct Supabase client call - see
  /// docwellness-backend's /auth/refresh). Makes its own raw Dio call
  /// rather than going through AuthService/request() itself, since this IS
  /// what request() calls before every request - going through request()
  /// here would recurse. A no-op when there's no session yet, or the
  /// current token isn't actually close to expiring - same ~30s threshold
  /// main.dart's own cold-start refresh check uses.
  Future<void> _refreshTokenIfNeeded() async {
    final session = SessionService.to;
    final expiresAt = int.tryParse(session.tokenExpiresAt ?? '');
    final refreshToken = session.refreshToken;
    if (expiresAt == null || refreshToken == null || refreshToken.isEmpty) return;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowSeconds < expiresAt - 30) return;

    try {
      final response = await _dio.request(
        '${AppConfig.patientApiBaseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(method: 'POST', contentType: 'application/json'),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await session.setSession(
          token: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: data['expiresAt'],
        );
        main_app.token = data['accessToken'];
      }
      // A non-200 here (dead refresh token) is left for the original
      // request to surface as its own 401 - _handleUnauthorized below
      // already handles that by clearing the session and redirecting to
      // login, so there's nothing extra to do in this branch.
    } catch (e) {
      // Network/timeout reaching /auth/refresh - proceed with the
      // (possibly stale) cached token rather than blocking the request
      // entirely; matches main.dart's own "offline shouldn't force a
      // logout" convention for the same class of failure.
      debugPrint('_refreshTokenIfNeeded failed (non-fatal): $e');
    }
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
    await _refreshTokenIfNeeded();
    // Callers build their own `headers: {'Authorization': 'Bearer $token'}`
    // map before calling request() - if _refreshTokenIfNeeded() just
    // rotated the token, that map still holds the stale value, since it was
    // already evaluated at the call site. Overwrite it with whatever's
    // current in SessionService now, rather than trusting what was passed
    // in, so a refresh that happens right here actually takes effect on
    // this same request instead of one request later.
    final effectiveHeaders = headers != null && headers.containsKey('Authorization')
        ? {...headers, 'Authorization': 'Bearer ${SessionService.to.token}'}
        : headers;
    final url = '${AppConfig.patientApiBaseUrl}$endPoint';
    debugPrint("🌐 API Request: $method $url");
    try {
      Response response = await _dio.request(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: effectiveHeaders,
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
