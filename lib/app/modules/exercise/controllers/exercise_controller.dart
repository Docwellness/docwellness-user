import 'package:docwellness/app/modules/exercise/models/exercise_stats_model.dart';
import 'package:docwellness/app/modules/exercise/service/exercise_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExerciseController extends GetxController {
  final ExerciseService _service = ExerciseService();

  Rx<ExerciseStats> stats = ExerciseStats.empty().obs;
  RxBool isLoading = false.obs;
  RxBool hasActivePlan = false.obs;

  // Which day the Exercise screen is showing - day-wise browsing/logging,
  // same pattern as DietController.selectedDate/switchDate for the Diet
  // Plan tab. Defaults to today.
  Rx<DateTime> selectedDate = DateTime.now().obs;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ExercisePlan has no week-numbering/weekStartDate of its own (unlike
  // DietPlan - just one recurring dailyExercises[] list keyed by the same
  // Monday/Tuesday/Wednesday/Thursday day-group rotation, see
  // ExercisePlan.js), so the browsable range is always the plain calendar
  // Monday-Sunday week, not anchored to a plan start date.
  DateTime get currentWeekStart => _today.subtract(Duration(days: _today.weekday - 1));
  DateTime get currentWeekEnd => currentWeekStart.add(const Duration(days: 6));

  bool isDateInCurrentWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(currentWeekStart) && !d.isAfter(currentWeekEnd);
  }

  bool get isSelectedDateFuture {
    final d = DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day);
    return d.isAfter(_today);
  }

  @override
  void onInit() {
    super.onInit();
    fetchTodayStats();
  }

  Future<void> fetchTodayStats({DateTime? date}) async {
    isLoading.value = true;
    final effectiveDate = date ?? selectedDate.value;
    selectedDate.value = effectiveDate;
    final dateStr = DateFormat('yyyy-MM-dd').format(effectiveDate);

    final planResult = await _service.getActiveExercisePlan();
    hasActivePlan.value = planResult != null && planResult != ExerciseService.noActivePlan;

    final data = await _service.getTodayExerciseStats(date: dateStr);
    stats.value = data != null ? ExerciseStats.fromJson(data) : ExerciseStats.empty();

    isLoading.value = false;
  }

  /// Switches which day's exercises are shown - pure client-side selection
  /// plus a real refetch (unlike DietController.switchDate, there's no
  /// week's-worth-of-data already cached client-side to swap between; each
  /// day's planned+logged exercises come from their own /today-stats call).
  void switchDate(DateTime date) {
    if (!isDateInCurrentWeek(date)) return;
    fetchTodayStats(date: date);
  }

  Future<bool> logExercise({
    required String exerciseId,
    int? durationMinutes,
    int? sets,
    int? reps,
  }) async {
    // The day currently being viewed, not "now" - this used to always log
    // against DateTime.now() regardless of which day's screen was open, so
    // logging a missed exercise from a previous day silently landed on
    // today's log instead (same bug already fixed for Log Meal - see
    // DietController.sendLogMeal).
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final success = await _service.submitExerciseLog(
      date: dateStr,
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
      await fetchTodayStats(date: selectedDate.value);
    }
    return success;
  }
}
