import 'package:dio/dio.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

class DietService {
  final ApiService service = ApiService();

  Future<dynamic> getActiveDiet(String date, {int? week}) async {
    try {
      String endpoint = '/diet/active?date=$date';
      if (week != null) {
        endpoint += '&week=$week';
      }
      final response = await service.request(
        endPoint: endpoint,
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

  Future<dynamic> getLogMeal(String date) async {
    try {
      final response = await service.request(
        endPoint: '/meal-log/screen-data?date=$date',
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

  Future<dynamic> sendLogMeal(Map<String, dynamic> data, String date) async {
    try {
      final response = await service.request(
        data: data,
        endPoint: '/meal-log',
        method: 'POST',
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

  Future<dynamic> createMyFood(FormData formData) async {
    try {
      final response = await service.request(
        endPoint: '/custom-food',
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

  Future<dynamic> getTodayMealLogStats({String? date, bool silent = false}) async {
    try {
      String endpoint = '/meal-log/today-stats';
      if (date != null) endpoint += '?date=$date';
      final response = await service.request(
        endPoint: endpoint,
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
        silent: silent,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }
}
