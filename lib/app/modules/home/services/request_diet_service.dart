import 'package:dio/dio.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:flutter/foundation.dart';

class RequestDietService {
  final ApiService service = ApiService();

  final String sendRequestDietPlanPath = '/diet-plan-requests';
  final String getRequestStatusPath = '/diet-plan-requests/status';
  final String getUserInfoPath = '/auth/me';
  final String sendPaymentInfoPath = '/payments/manual-proof';
  final String updateProfilePath = '/profile';
  final String updateHealthProfilePath = '/health-profile';
  final String validateCouponPath = '/coupons/validate';

  Future<dynamic> getUserInfo() async {
    try {
      final response = await service.request(
        endPoint: getUserInfoPath,
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  /// Get the current diet plan request status
  Future<dynamic> getRequestStatus() async {
    try {
      final response = await service.request(
        endPoint: getRequestStatusPath,
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> sendRequestDietPlan(Map<String, dynamic> body) async {
    try {
      final response = await service.request(
        endPoint: sendRequestDietPlanPath,
        method: 'POST',
        data: body,
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  /// Persists the chosen membership plan onto an existing diet plan request.
  Future<dynamic> selectMembershipPlan({
    required String requestId,
    required String membershipPlan,
    required double membershipAmount,
  }) async {
    try {
      final response = await service.request(
        endPoint: '/diet-plan-requests/$requestId/plan',
        method: 'PATCH',
        data: {
          'membershipPlan': membershipPlan,
          'membershipAmount': membershipAmount,
        },
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> sendPaymentInfo(Map<String, dynamic> body) async {
    try {
      final formData = FormData.fromMap(body);
      final response = await service.request(
        endPoint: sendPaymentInfoPath,
        method: 'POST',
        data: formData,
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> updateProfile(Map<String, dynamic> body) async {
    try {
      final response = await service.request(
        endPoint: updateProfilePath,
        method: 'PUT',
        data: body,
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> updateHealthProfile(Map<String, dynamic> body) async {
    try {
      final response = await service.request(
        endPoint: updateHealthProfilePath,
        method: 'PUT',
        data: body,
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(filePath),
      });
      debugPrint('📸 Uploading profile image from: $filePath');
      final response = await service.request(
        endPoint: '/profile/image',
        method: 'POST',
        data: formData,
        headers: {'Authorization': "Bearer $token"},
      );
      debugPrint(
        '📸 Upload response: ${response?.statusCode} ${response?.data}',
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']['imageUrl'];
      }
    } catch (e) {
      debugPrint('📸 Upload error: $e');
    }
    return null;
  }

  /// Validate a coupon code and get discount info
  Future<dynamic> validateCoupon(String code) async {
    try {
      final response = await service.request(
        endPoint: validateCouponPath,
        method: 'POST',
        data: {'code': code},
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }

      // Return error message from server
      if (response != null && response.data != null) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }
}
