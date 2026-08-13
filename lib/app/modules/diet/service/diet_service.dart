import 'package:dio/dio.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

class DietService {
  final ApiService service = ApiService();

  // Sentinel returned when the backend confirms (404, "Active diet plan not
  // found" - see getActiveDietPlanForPatient) that the patient genuinely
  // has no active plan yet, as opposed to a network/server failure - both
  // used to collapse to the same `null`, which meant DietController
  // couldn't tell "confirmed nothing to show" apart from "we don't know,
  // the request failed" (see AI_EXECUTION_PLAN.md Phase 8's release-
  // checklist note on missing error states). Kept as a same-file constant
  // rather than a shared enum since this is the only place that needs it.
  static const noActivePlan = '__no_active_plan__';

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
      if (response != null && response.statusCode == 404) {
        return noActivePlan;
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/patient/diet/week-completion?week=N - real per-day/week
  /// meal-logging completion, used to collapse a fully-logged week's day
  /// strip into a single chip (see diet_view.dart).
  Future<dynamic> getWeekCompletion(int week) async {
    try {
      final response = await service.request(
        endPoint: '/diet/week-completion?week=$week',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
        silent: true,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data'];
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

  Future<dynamic> getTodayMealLogStats({
    String? date,
    bool silent = false,
  }) async {
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
