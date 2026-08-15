import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

class ExerciseService {
  final ApiService service = ApiService();

  // Mirrors DietService's noActivePlan sentinel - lets ExerciseController
  // tell "confirmed no active exercise plan" (404) apart from "request
  // failed" (null), rather than collapsing both to the same thing.
  static const noActivePlan = '__no_active_exercise_plan__';

  /// GET /api/patient/exercise/active
  Future<dynamic> getActiveExercisePlan() async {
    try {
      final response = await service.request(
        endPoint: '/exercise/active',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
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

  /// GET /api/patient/exercise-log/today-stats
  Future<dynamic> getTodayExerciseStats({String? date}) async {
    try {
      final response = await service.request(
        endPoint: date != null ? '/exercise-log/today-stats?date=$date' : '/exercise-log/today-stats',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/patient/exercise-log
  Future<bool> submitExerciseLog({
    required String date,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final response = await service.request(
        endPoint: '/exercise-log',
        method: 'POST',
        data: {'date': date, 'exercises': exercises},
        headers: {'Authorization': 'Bearer $token'},
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
