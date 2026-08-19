import 'package:dio/dio.dart';
import 'package:docwellness/main.dart' as main_app;
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:flutter/widgets.dart';

/// Distinguishes why /auth/me didn't return a profile - getUserInfo() used
/// to collapse every failure (network error, expired/invalid token, and a
/// genuine "email verified but registration never finished") into a plain
/// null, which made a momentarily-stale access token on cold start
/// indistinguishable from an actually-incomplete signup - see
/// main.dart's getUserData().
class UserInfoResult {
  final Map<String, dynamic>? data;
  final int? statusCode;

  const UserInfoResult({this.data, this.statusCode});

  bool get isSuccess => data != null;
  // Backend's authMiddleware: 409 + code 'no_profile' means the Supabase
  // identity is real but no Mongo profile was ever linked (registration
  // interrupted before completeRegistration ran) - see
  // docwellness-backend/middlewares/auth.js.
  bool get isNoProfile => statusCode == 409;
  // Any other non-200 (401 expired/invalid token, etc.) - never treat this
  // as "no profile"; it says nothing about whether one exists.
  bool get isUnauthorized => statusCode == 401;
}

class AuthService {
  final ApiService service = ApiService();
  final String signupRequestEndPoint = '/auth/signup-request';
  final String verifySignupOtpEndPoint = '/auth/verify-signup-otp';
  final String loginEndPoint = '/auth/login';
  final String registerEndPoint = '/auth/register';
  final String forgotPasswordEndPoint = '/auth/forgot-password';
  final String resetPasswordEndPoint = '/auth/reset-password';
  final String refreshEndPoint = '/auth/refresh';
  final String changePasswordEndPoint = '/auth/change-password';
  final String logoutEndPoint = '/auth/logout';

  /// Step 1 of signup: creates the Supabase identity and emails a
  /// verification code. Doesn't need an Authorization header (no session
  /// exists yet).
  Future<Map<String, dynamic>> signupRequest({
    required String email,
    required String password,
  }) async {
    return _postAndFormat(
      signupRequestEndPoint,
      {'email': email, 'password': password},
      expectedStatus: 200,
    );
  }

  /// Step 2 of signup: verifies the emailed code and returns a Supabase
  /// session - server-side replacement for the app calling
  /// supabase.auth.verifyOtp(type: 'signup') directly. On success,
  /// `data['data']` has `accessToken`/`refreshToken`/`expiresAt`.
  Future<Map<String, dynamic>> verifySignupOtp({
    required String email,
    required String code,
  }) async {
    return _postAndFormat(
      verifySignupOtpEndPoint,
      {'email': email, 'code': code},
      expectedStatus: 200,
    );
  }

  /// Log in with email/password - server-side replacement for
  /// supabase.auth.signInWithPassword(). On success, `data['data']` has
  /// `accessToken`/`refreshToken`/`expiresAt`. `headers` carries the
  /// Phase 9 device-integrity signal (see DeviceSecurityService) - login
  /// is the only unauthenticated call that needs custom headers, so this
  /// is the only method here that exposes the parameter.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    Map<String, dynamic>? headers,
  }) async {
    return _postAndFormat(
      loginEndPoint,
      {'email': email, 'password': password},
      expectedStatus: 200,
      headers: headers,
    );
  }

  /// Step 3 of signup: links the now-verified Supabase identity to a new
  /// Mongo profile. Call after verifySignupOtp succeeds and has set the
  /// `token` global to the fresh Supabase access token - ApiService has no
  /// auto-attaching interceptor in this app (unlike some others), so the
  /// header is attached explicitly here, matching every other authenticated
  /// call site in this codebase.
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    return _postAndFormat(
      registerEndPoint,
      body,
      expectedStatus: 201,
      headers: {'Authorization': 'Bearer ${main_app.token}'},
    );
  }

  /// Completes the forgot-password flow: verifies the emailed code and sets
  /// the new password in one call - server-side replacement for the app's
  /// old verifyOtp -> updateUser -> signOut sequence. No session is
  /// returned; the caller sends the patient back to the login screen.
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return _postAndFormat(
      resetPasswordEndPoint,
      {'email': email, 'code': code, 'newPassword': newPassword},
      expectedStatus: 200,
    );
  }

  /// Exchanges a refresh token for a new session - server-side replacement
  /// for supabase.auth.refreshSession(). Used by main.dart's cold-start
  /// session restore; the proactive pre-request refresh in
  /// utils/functions/dio_function.dart's ApiService.request() makes its own
  /// raw call instead of going through this class, to avoid recursing back
  /// into ApiService.request() itself.
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    return _postAndFormat(
      refreshEndPoint,
      {'refreshToken': refreshToken},
      expectedStatus: 200,
    );
  }

  /// Changes the current patient's password (reauthenticates with the
  /// current one server-side, then sets the new one and signs out every
  /// other session on the account) - server-side replacement for the app's
  /// old signInWithPassword -> updateUser -> signOut(scope: others)
  /// sequence.
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _postAndFormat(
      changePasswordEndPoint,
      {'currentPassword': currentPassword, 'newPassword': newPassword},
      expectedStatus: 200,
      headers: {'Authorization': 'Bearer ${main_app.token}'},
    );
  }

  /// Logs out - revokes the current Supabase session server-side
  /// (replacing supabase.auth.signOut()). Best-effort: callers should clear
  /// local session state regardless of whether this call succeeds (e.g. the
  /// token may already be expired, in which case there's nothing left to
  /// revoke anyway).
  Future<void> logout() async {
    try {
      await service.request(
        endPoint: logoutEndPoint,
        method: 'POST',
        headers: {'Authorization': 'Bearer ${main_app.token}'},
        silent: true,
      );
    } catch (e) {
      debugPrint('logout error: $e');
    }
  }

  Future<Map<String, dynamic>> _postAndFormat(
    String endPoint,
    Map<String, dynamic> body, {
    required int expectedStatus,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await service.request(
        endPoint: endPoint,
        method: 'POST',
        data: body,
        headers: headers,
      );

      if (response != null &&
          response.statusCode == expectedStatus &&
          response.data['success'] == true) {
        return {'success': true, 'data': response.data};
      }

      if (response != null && response.data != null) {
        // Phase 9, P9-U6: status code only, not the raw response body -
        // this fires for every failed /auth/* call including /auth/refresh,
        // and logging the body wholesale risks incidentally leaking a
        // token or PHI field if a future response shape ever carries one.
        debugPrint('⚠️ $endPoint failed: ${response.statusCode}');
        String message = 'Something went wrong. Please try again.';
        if (response.data is Map) {
          if (response.data['errors'] != null &&
              response.data['errors'] is List &&
              (response.data['errors'] as List).isNotEmpty) {
            final errors = response.data['errors'] as List;
            message = errors.join('\n');
          } else {
            message = response.data['message'] ?? message;
          }
        }
        final result = <String, dynamic>{
          'success': false,
          'message': message,
          'statusCode': response.statusCode,
        };
        // Phase 9, P9-U3: surface the backend's login-lockout retryAfter
        // (body field, falling back to the Retry-After header) so the UI
        // can show a countdown instead of a bare error message.
        if (response.statusCode == 429) {
          final bodyRetryAfter =
              response.data is Map ? response.data['retryAfter'] : null;
          result['retryAfter'] = bodyRetryAfter is int
              ? bodyRetryAfter
              : int.tryParse(bodyRetryAfter?.toString() ?? '') ??
                    int.tryParse(response.headers.value('retry-after') ?? '') ??
                    300;
        }
        return result;
      }

      return {
        'success': false,
        'message': 'No response from server. Please try again.',
      };
    } on DioException catch (e) {
      debugPrint('❌ $endPoint DioException: ${e.type} - ${e.message}');
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Request timed out. Please try again.';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Cannot connect to server. Check if you\'re using the right network (emulator vs device).';
          break;
        default:
          errorMessage = 'Network error: ${e.message}';
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      debugPrint('❌ $endPoint error: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
      };
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await service.request(
        endPoint: forgotPasswordEndPoint,
        method: 'POST',
        data: {'email': email},
      );
    } catch (e) {
      debugPrint('forgotPassword error: $e');
    }
    // Always resolves quietly - the backend responds with the same generic
    // message regardless of whether the email exists, so there's nothing
    // meaningful to branch on here either.
  }

  Future<UserInfoResult> getUserInfo(String token) async {
    try {
      final response = await service.request(
        endPoint: '/auth/me',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        // Silent: this is called from the app's own boot sequence (and
        // from login/loadUserData) - a transient failure here shouldn't
        // pop a dialog on top of whatever screen is being decided; the
        // caller reacts to the result directly instead.
        silent: true,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return UserInfoResult(data: response.data, statusCode: 200);
      }
      return UserInfoResult(statusCode: response?.statusCode);
    } catch (e) {
      debugPrint('-----------------------> $e');
      return const UserInfoResult();
    }
  }
}
