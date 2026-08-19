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

  // Phase 9, P9-U1: shared across every ApiService() instance (constructed
  // fresh at 15+ call sites - AuthService, DietService, ExerciseService,
  // etc.) so concurrent requests near token expiry de-dupe onto one
  // /auth/refresh call instead of each firing their own ("thundering
  // herd" - a static field, not an instance field, is what makes this
  // shared across instances).
  static Future<void>? _refreshInFlight;

  /// Proactively refreshes the access token before it expires, replacing
  /// the Supabase SDK's own background auto-refresh timer (removed
  /// alongside every other direct Supabase client call - see
  /// docwellness-backend's /auth/refresh). Makes its own raw Dio call
  /// rather than going through AuthService/request() itself, since this IS
  /// what request() calls before every request - going through request()
  /// here would recurse. With `force: false` (the pre-request check) this
  /// is a no-op unless the token is actually close to expiring - same
  /// ~30s threshold main.dart's own cold-start refresh check uses.
  /// `force: true` skips that check - used after a live 401 (see
  /// request() below), where the server has already decided the token is
  /// dead regardless of what our local clock thinks.
  Future<void> _refreshTokenIfNeeded({bool force = false}) {
    return _refreshInFlight ??= _doRefreshToken(force: force).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _doRefreshToken({required bool force}) async {
    final session = SessionService.to;
    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return;

    if (!force) {
      final expiresAt = int.tryParse(session.tokenExpiresAt ?? '');
      if (expiresAt == null) return;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowSeconds < expiresAt - 30) return;
    }

    try {
      final response = await _dio.request(
        '${AppConfig.patientApiBaseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(method: 'POST', contentType: 'application/json'),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        // setSession() already persists the token via SessionService -
        // main.dart's `token` global is just a getter/setter bridge over
        // the same SessionService field, so re-assigning it here would be
        // a redundant no-op write.
        await session.setSession(
          token: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: data['expiresAt'],
        );
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
    // Phase 9, P9-U2: set internally when retrying after a refresh-on-401 -
    // guarantees at most one retry per original call, never an infinite loop.
    bool isRetryAfterRefresh = false,
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

      // Expired / invalid token. One refresh-and-retry (guarded by
      // isRetryAfterRefresh so this can only happen once per original
      // call) before giving up - closes the gap where the server already
      // considers the token dead even though the pre-request check above
      // (only refreshes within ~30s of the locally-cached expiry) hadn't
      // kicked in yet. Mirrors docwellness-dietician's existing
      // isRetryAfterRefresh pattern.
      if (e.response?.statusCode == 401) {
        if (!isRetryAfterRefresh) {
          final tokenBeforeRefresh = SessionService.to.token;
          await _refreshTokenIfNeeded(force: true);
          final tokenAfterRefresh = SessionService.to.token;
          if (tokenAfterRefresh != null &&
              tokenAfterRefresh.isNotEmpty &&
              tokenAfterRefresh != tokenBeforeRefresh) {
            return request(
              endPoint: endPoint,
              method: method,
              data: data,
              queryParameters: queryParameters,
              headers: headers,
              silent: silent,
              isRetryAfterRefresh: true,
            );
          }
        }
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
