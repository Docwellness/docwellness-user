import 'package:docwellness/app/modules/exercise/models/exercise_stats_model.dart';
import 'package:docwellness/app/modules/exercise/service/exercise_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExerciseController extends GetxController {
  final ExerciseService _service = ExerciseService();

  Rx<ExerciseStats> stats = ExerciseStats.empty().obs;
  RxBool isLoading = false.obs;
  RxBool hasActivePlan = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTodayStats();
  }

  Future<void> fetchTodayStats({DateTime? date}) async {
    isLoading.value = true;
    final dateStr = DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());

    final planResult = await _service.getActiveExercisePlan();
    hasActivePlan.value = planResult != null && planResult != ExerciseService.noActivePlan;

    final data = await _service.getTodayExerciseStats(date: dateStr);
    stats.value = data != null ? ExerciseStats.fromJson(data) : ExerciseStats.empty();

    isLoading.value = false;
  }

  Future<bool> logExercise({
    required String exerciseId,
    int? durationMinutes,
    int? sets,
    int? reps,
  }) async {
    final success = await _service.submitExerciseLog(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      exercises: [
        {
          'exerciseId': exerciseId,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (sets != null) 'sets': sets,
          if (reps != null) 'reps': reps,
        },
      ],
    );
    if (success) {
      await fetchTodayStats();
    }
    return success;
  }
}
