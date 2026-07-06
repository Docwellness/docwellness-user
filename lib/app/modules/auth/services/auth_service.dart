import 'package:dio/dio.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:flutter/widgets.dart';

class AuthService {
  final ApiService service = ApiService();
  final String signUpEndPoint = '/auth/register';
  final String loginEndPoint = '/auth/login';

  Future<Map<String, dynamic>> signUp(Map<String, dynamic> body) async {
    try {
      final response = await service.request(
        endPoint: signUpEndPoint,
        method: 'POST',
        data: body,
      );

      if (response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true) {
        return {'success': true, 'data': response.data};
      }

      // Return the actual error message from backend
      if (response != null && response.data != null) {
        debugPrint(
          '⚠️ Signup failed: ${response.statusCode} - ${response.data}',
        );
        String message = 'Signup failed. Please try again.';

        if (response.data is Map) {
          // Try to get specific error messages
          if (response.data['errors'] != null &&
              response.data['errors'] is List &&
              (response.data['errors'] as List).isNotEmpty) {
            // Validation errors array
            final errors = response.data['errors'] as List;
            message = errors.map((e) => e['msg'] ?? e.toString()).join('\n');
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
      debugPrint('❌ signUp DioException: ${e.type} - ${e.message}');
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
      debugPrint('❌ signUp error: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
      };
    }
  }

  Future<dynamic> login(Map<String, dynamic> body) async {
    try {
      final response = await service.request(
        endPoint: loginEndPoint,
        method: 'POST',
        data: body,
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
