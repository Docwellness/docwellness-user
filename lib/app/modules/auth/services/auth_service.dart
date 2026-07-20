import 'package:dio/dio.dart';
import 'package:docwellness/main.dart' as main_app;
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:flutter/widgets.dart';

class AuthService {
  final ApiService service = ApiService();
  final String signupRequestEndPoint = '/auth/signup-request';
  final String registerEndPoint = '/auth/register';
  final String forgotPasswordEndPoint = '/auth/forgot-password';

  /// Step 1 of signup: creates the Supabase identity and emails a
  /// verification code. Doesn't need an Authorization header (no session
  /// exists yet).
  Future<Map<String, dynamic>> signupRequest({
    required String email,
    required String password,
    required String username,
  }) async {
    return _postAndFormat(
      signupRequestEndPoint,
      {'email': email, 'password': password, 'username': username},
      expectedStatus: 200,
    );
  }

  /// Step 2 of signup: links the now-verified Supabase identity to a new
  /// Mongo profile. Call after supabase.auth.verifyOTP(type: signup)
  /// succeeds and has set the `token` global to the fresh Supabase access
  /// token - ApiService has no auto-attaching interceptor in this app
  /// (unlike some others), so the header is attached explicitly here,
  /// matching every other authenticated call site in this codebase.
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    return _postAndFormat(
      registerEndPoint,
      body,
      expectedStatus: 201,
      headers: {'Authorization': 'Bearer ${main_app.token}'},
    );
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
        debugPrint('⚠️ $endPoint failed: ${response.statusCode} - ${response.data}');
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
        return {'success': false, 'message': message};
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

  /// Resolves a username to its email so the app can sign in via Supabase
  /// (email-only) even when the user typed a username.
  Future<String?> resolveUsernameToEmail(String username) async {
    try {
      final response = await service.request(
        endPoint: '/auth/resolve-username/$username',
        method: 'GET',
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']['email'] as String?;
      }
    } catch (e) {
      debugPrint('resolveUsernameToEmail error: $e');
    }
    return null;
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

  Future<dynamic> getUserInfo(String token) async {
    try {
      final response = await service.request(
        endPoint: '/auth/me',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
    }
    return null;
  }
}
