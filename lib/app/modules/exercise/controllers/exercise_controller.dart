import 'package:docwellness/app/modules/exercise/models/exercise_stats_model.dart';
import 'package:docwellness/app/modules/exercise/service/exercise_service.dart';
import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExerciseController extends GetxController {
  final ExerciseService _service = ExerciseService();

  Rx<ExerciseStats> stats = ExerciseStats.empty().obs;
  RxBool isLoading = false.obs;
  RxBool hasActivePlan = false.obs;

  // Every fetched day's stats, keyed by 'yyyy-MM-dd' - lets switchDate be a
  // pure client-side swap (no network call, no loading flash) for any day
  // already prefetched, same as DietController.switchDate reads off
  // activeDietData's already-fetched week instead of refetching per tap.
  // Populated both by the initial/current-day fetch and by
  // _prefetchWeek's fire-and-forget background pass over the rest of the
  // current week (see onInit).
  final Map<String, ExerciseStats> _statsCache = {};

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
    fetchTodayStats().then((_) => _prefetchWeek());
  }

  Future<void> fetchTodayStats({DateTime? date}) async {
    isLoading.value = true;
    final effectiveDate = date ?? selectedDate.value;
    selectedDate.value = effectiveDate;
    final dateStr = DateFormat('yyyy-MM-dd').format(effectiveDate);

    final planResult = await _service.getActiveExercisePlan();
    hasActivePlan.value = planResult != null && planResult != ExerciseService.noActivePlan;

    final data = await _service.getTodayExerciseStats(date: dateStr);
    final resolved = data != null ? ExerciseStats.fromJson(data) : ExerciseStats.empty();
    stats.value = resolved;
    _statsCache[dateStr] = resolved;

    isLoading.value = false;
  }

  /// Fire-and-forget background pass over the rest of the current week
  /// (the initial/current day is already cached by fetchTodayStats above),
  /// so every day in the strip is instant once tapped instead of showing a
  /// loading flash per click - see switchDate.
  Future<void> _prefetchWeek() async {
    for (var i = 0; i < 7; i++) {
      final day = currentWeekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      if (_statsCache.containsKey(dateStr)) continue;
      final data = await _service.getTodayExerciseStats(date: dateStr);
      _statsCache[dateStr] = data != null ? ExerciseStats.fromJson(data) : ExerciseStats.empty();
    }
  }

  /// Read-only peek at a specific day's stats - checks _statsCache first,
  /// else fetches and caches, but never touches selectedDate/stats (the
  /// live displayed page). Used by Goal Journey's "Log Exercise" card (see
  /// milestone_sheet.dart's _LogExerciseProgressCard) to preview a day's
  /// exercises without silently changing what the Exercise tab itself is
  /// showing if the patient later opens it normally.
  Future<ExerciseStats> statsForDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final cached = _statsCache[dateStr];
    if (cached != null) return cached;

    final data = await _service.getTodayExerciseStats(date: dateStr);
    final resolved = data != null ? ExerciseStats.fromJson(data) : ExerciseStats.empty();
    _statsCache[dateStr] = resolved;
    return resolved;
  }

  /// Switches which day's exercises are shown - pure client-side swap from
  /// _statsCache when that day's already been prefetched (the normal case
  /// once _prefetchWeek has run), same as DietController.switchDate reading
  /// off activeDietData's already-fetched week instead of refetching per
  /// tap. Only falls back to a real network fetch on a genuine cache miss
  /// (e.g. tapping a day before _prefetchWeek has reached it yet).
  void switchDate(DateTime date) {
    if (!isDateInCurrentWeek(date)) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final cached = _statsCache[dateStr];
    if (cached != null) {
      selectedDate.value = date;
      stats.value = cached;
      return;
    }
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
      _refreshGoalJourney();
    }
    return success;
  }

  /// Un-logs an already-logged exercise for the day currently being
  /// viewed - same idea as Log Meal's portion-back-to-0 (see
  /// LogMealContainer/submitMealLog's servings: 0 handling), just signaled
  /// with an explicit `remove` flag instead of a 0 value, since exercises
  /// have no single "portion" field to zero out.
  Future<bool> removeExerciseLog(String exerciseId) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final success = await _service.submitExerciseLog(
      date: dateStr,
      exercises: [
        {'exerciseId': exerciseId, 'remove': true},
      ],
    );
    if (success) {
      await fetchTodayStats(date: selectedDate.value);
      _refreshGoalJourney();
    }
    return success;
  }

  /// Goal Journey's "Log Exercise" task (see seedGoalTimeline.js's
  /// EXERCISE_TASK_TITLE) reads off TimelineController's cached /timeline
  /// data - without this it kept showing the day as exercise-incomplete
  /// until some unrelated trigger refreshed it, same reasoning as
  /// DietController.sendLogMeal's identical call for Log Meal.
  void _refreshGoalJourney() {
    if (Get.isRegistered<TimelineController>()) {
      Get.find<TimelineController>().load(silent: true);
    }
  }
}
