import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

class DoctorProfileService {
  final ApiService _apiService = ApiService();

  Future<DoctorProfileModel?> getAssignedDoctorProfile({
    bool silent = false,
  }) async {
    try {
      final response = await _apiService.request(
        endPoint: '/assigned-doctor/profile',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        silent: silent,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return DoctorProfileModel.fromJson(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getDoctorPosts() async {
    try {
      final response = await _apiService.request(
        endPoint: '/quotes',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (_) {}
    return [];
  }
}
