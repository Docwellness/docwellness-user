import 'package:dio/dio.dart' as dio;
import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/app/models/log_meal_model.dart';
import 'package:docwellness/app/modules/diet/service/diet_service.dart';
import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class DietController extends GetxController {
  final ImagePicker picker = ImagePicker();

  ActiveDietData? activeDietData;

  // Recipe lookup cache, keyed by "yyyy-MM-dd|servingTime" (AI_EXECUTION_
  // PLAN.md Phase 6, P6-05) - getRecipesForServing() re-filters/re-scales
  // activeDietData's dailyMeals on every call, which repeats on every tab
  // switch/rebuild for a day+slot the patient is just looking at, not new
  // data. Cleared in getActiveDiet() below whenever a fetch actually
  // replaces activeDietData ("clear cache when diet plan changes").
  final Map<String, List<Recipe>> _recipesCache = {};
  LogMealData? logMealData;
  final DietService service = DietService();
  RxMap<String, int> selectedPortions = <String, int>{}.obs;

  RxBool showActiveDietPlanLoading = false.obs;
  RxBool showLogMealLoading = false.obs;
  RxBool showSendLogMealLoading = false.obs;
  RxBool showCreateMealLoading = false.obs;

  // Set when getActiveDiet()'s fetch fails outright (network/server error) -
  // distinct from activeDietData being null because the patient genuinely
  // has no diet plan yet. Without this, a failed fetch silently rendered
  // the same "No diet assigned" empty state as a real "nothing assigned"
  // case, with no retry affordance (see diet_view.dart's AppErrorState use).
  RxBool hasDietLoadError = false.obs;

  RxInt selectedWeek = 0.obs;
  RxInt totalWeeks = 4.obs;

  // Real per-week meal-logging completion (week number -> fully logged?),
  // fetched from the backend's getWeekCompletion (not derived client-side -
  // it needs the plan's dailyMeals + real MealLog data neither of which the
  // day-strip already has in a form that's safe to recompute from). Powers
  // diet_view.dart's collapsed "Week N" chip for a week that's fully done.
  RxMap<int, bool> weekCompletion = <int, bool>{}.obs;

  // Which week (if any) the patient tapped to manually re-expand after it
  // collapsed into a "Week N" chip for being complete - 0 means none, so
  // every completed week defaults to collapsed again on next visit. Only
  // ever applies to selectedWeek (see diet_view.dart's _buildWeekRow) -
  // every other week always shows as a plain switchable chip regardless.
  RxInt expandedWeek = 0.obs;

  Future<void> fetchWeekCompletion(int week) async {
    final data = await service.getWeekCompletion(week);
    if (data != null && data['complete'] is bool) {
      weekCompletion[week] = data['complete'] as bool;
    }
  }

  void toggleExpandWeek(int week) {
    expandedWeek.value = expandedWeek.value == week ? 0 : week;
  }

  // Set to a tab index (e.g. the Supplements tab) to ask DietPlanScreen to
  // jump its TabController there next time it's visible - used when arriving
  // from outside this screen (e.g. tapping Supplements in the Goal Journey
  // sheet), which has no other way to reach into DietPlanScreen's own
  // TabController. -1 means no pending request.
  RxInt focusTabRequest = (-1).obs;

  RxString selectedLogMealDate = ''.obs;

  // Which real calendar date's meals the Diet Plan screen is showing -
  // defaults to today. Bounded to the current Mon-Sun week (see
  // isDateInCurrentWeek) since a day-group only resolves within "this
  // week's" 4-group cycle - the separate Week 1-4 selector above is for
  // browsing the diet plan's own week blocks, not individual dates.
  Rx<DateTime> selectedDate = DateTime.now().obs;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // The day-strip's 7-day window anchors to the plan's own weekStartDate
  // (backend-computed from the dietician's chosen/rescheduled start date -
  // see weekSchedule.js's buildWeekSchedule) rather than the calendar's
  // Monday-Sunday grid. A plan can start on any weekday (e.g. a plan
  // activated today, a Tuesday, runs Tue-Mon) - anchoring to calendar
  // Monday instead made every day before today read as "past" and grayed
  // out even when it was never part of the plan's own week at all. Falls
  // back to calendar-Monday only before the plan has loaded.
  DateTime get currentWeekStart {
    final planWeekStart = activeDietData?.weekStartDate;
    if (planWeekStart != null) {
      return DateTime(
        planWeekStart.year,
        planWeekStart.month,
        planWeekStart.day,
      );
    }
    return _today.subtract(Duration(days: _today.weekday - 1));
  }

  DateTime get currentWeekEnd => currentWeekStart.add(const Duration(days: 6));

  /// Day-strip range: any day of the current calendar week, past/today/
  /// future - future days are viewable as a preview, just with logging
  /// disabled (see isSelectedDateFuture).
  bool isDateInCurrentWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(currentWeekStart) && !d.isAfter(currentWeekEnd);
  }

  /// Log Meal date-picker range: current week, but never in the future -
  /// you can't log a meal that hasn't happened yet.
  bool isDateLoggable(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return isDateInCurrentWeek(d) && !d.isAfter(_today);
  }

  // Mirrors the backend's Monday=Friday/Tuesday=Saturday/Wednesday=Sunday/
  // Thursday-unique grouping (utils/dayGroups.js) - now that a week's
  // dailyMeals carries all 4 groups together in one response instead of the
  // backend pre-filtering to just one, this is how the client picks the
  // right group for whichever date is selected without a network call.
  // Dart's DateTime.weekday is already 1=Mon..7=Sun, so it maps directly.
  static const Map<int, String> _weekdayToDayGroup = {
    DateTime.monday: 'Monday',
    DateTime.friday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.saturday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.sunday: 'Wednesday',
    DateTime.thursday: 'Thursday',
  };

  String resolveDayGroupForDate(DateTime date) =>
      _weekdayToDayGroup[date.weekday] ?? 'Monday';

  // A meal with no dayGroup is pre-migration data that applied to every day
  // - same fallback as the backend's mealMatchesDayGroup.
  bool _mealMatchesDayGroup(DailyMeal meal, String dayGroup) =>
      meal.dayGroup == null ||
      meal.dayGroup!.isEmpty ||
      meal.dayGroup == dayGroup;

  bool get isSelectedDateFuture {
    final d = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );
    return d.isAfter(_today);
  }

  @override
  void onInit() {
    getActiveDiet();
    super.onInit();
  }

  Future<void> getActiveDiet({int? week, DateTime? date}) async {
    showActiveDietPlanLoading.value = true;
    hasDietLoadError.value = false;
    try {
      final effectiveDate = date ?? DateTime.now();
      selectedDate.value = effectiveDate;
      final dateStr = DateFormat('yyyy-MM-dd').format(effectiveDate);

      final response = await service.getActiveDiet(dateStr, week: week);

      if (response == DietService.noActivePlan) {
        // Confirmed by the backend - genuinely nothing to show, not a
        // failure. Clear any stale data from a previous successful fetch
        // (e.g. a plan that just ended) so NoDietWidget shows correctly.
        activeDietData = null;
      } else if (response != null) {
        activeDietData = ActiveDietData.fromJson(response['data']);
        selectedWeek.value = activeDietData!.currentWeek;
        totalWeeks.value = activeDietData!.totalWeeks > 0
            ? activeDietData!.totalWeeks
            : 4;
        // The diet plan changed (new fetch) - any previously cached
        // date+servingTime recipe lists are now stale.
        _recipesCache.clear();
        // Fire-and-forget for every week up to totalWeeks - each result
        // updates weekCompletion reactively as it arrives, without holding
        // up the diet plan itself from rendering.
        for (var w = 1; w <= totalWeeks.value; w++) {
          fetchWeekCompletion(w);
        }
        // AI_EXECUTION_PLAN.md Phase 8, P8-04 - no PHI: just the week
        // number, not any meal/nutrition content.
        Posthog().capture(
          eventName: 'diet_plan_viewed',
          properties: {'week': activeDietData!.currentWeek},
        );
      } else {
        // Unknown failure (network/server error) - distinct from a
        // confirmed "no active plan" above. Keep whatever activeDietData
        // is already showing (a stale-but-real plan beats an error screen
        // on a transient refresh failure) and only surface the error state
        // when there's nothing else to show instead.
        hasDietLoadError.value = true;
      }
    } catch (_) {
      hasDietLoadError.value = true;
    }
    showActiveDietPlanLoading.value = false;
  }

  /// Pure client-side swap when the target week was already returned by the
  /// last fetch (ActiveDietData.weeks - see backend's getActiveDietPlanForPatient,
  /// which already loads every week's data on every call regardless of which
  /// one was requested). Only falls back to a real network round trip - with
  /// its loading spinner - if that week genuinely isn't cached yet (e.g. an
  /// older cached ActiveDietData from before this field existed).
  void switchWeek(int week) {
    if (week == selectedWeek.value) return;
    // Switching to a different week always starts collapsed-if-complete -
    // see expandedWeek's own doc comment.
    expandedWeek.value = 0;
    WeekEntry? entry;
    for (final w in activeDietData?.weeks ?? const <WeekEntry>[]) {
      if (w.week == week) {
        entry = w;
        break;
      }
    }
    if (entry != null) {
      activeDietData = activeDietData!.copyWithWeek(entry);
      selectedWeek.value = week;
      // Same reasoning as getActiveDiet(): the underlying dailyMeals just
      // changed (different week), even though selectedDate (the cache
      // key's other half) didn't - a stale cache hit here would silently
      // show the previous week's recipes.
      _recipesCache.clear();
      return;
    }
    getActiveDiet(week: week);
  }

  /// Switches which day's meals the Diet Plan screen shows - see
  /// isDateInCurrentWeek for the selectable range. A week only has 4
  /// distinct day-groups (not 7 unique days - see resolveDayGroupForDate),
  /// and the last fetch already returned all of them together, so this is
  /// pure client-side state: no network call, no loading flash, just
  /// getRecipesForServing/getSupplementRecipes re-filtering by the newly
  /// selected date's group. Only falls back to a real fetch if nothing's
  /// loaded yet at all (shouldn't normally happen - isDateInCurrentWeek
  /// already bounds date to a week getActiveDiet's initial call covers).
  void switchDate(DateTime date) {
    if (!isDateInCurrentWeek(date)) return;
    selectedDate.value = date;
    if (activeDietData == null) {
      getActiveDiet(date: date);
    }
  }

  /// Recipes tagged 'supplement' across every serving-time slot for the
  /// currently selected day, de-duped by recipe id - powers the dedicated
  /// Supplements tab, since a supplement otherwise sits anonymously (with
  /// zeroed macros) inside whatever real servingTime slot it was assigned
  /// to, easy for a patient to miss entirely.
  List<Recipe> getSupplementRecipes() {
    if (activeDietData == null) return [];
    // week.dailyMeals now holds all 4 day-groups together (see
    // getActiveDietPlanForPatient) - scope down to the selected date's
    // group, same as getRecipesForServing below, so switching days doesn't
    // show every group's supplements mixed together.
    final dayGroup = resolveDayGroupForDate(selectedDate.value);
    final seen = <String>{};
    final result = <Recipe>[];
    for (final meal in activeDietData!.week.dailyMeals) {
      if (!_mealMatchesDayGroup(meal, dayGroup)) continue;
      final baseRecipe = activeDietData!.recipes[meal.recipeId];
      if (baseRecipe == null || !baseRecipe.tags.contains('supplement')) {
        continue;
      }
      if (!seen.add(baseRecipe.id)) continue;
      result.add(baseRecipe);
    }
    return result;
  }

  List<Recipe> getRecipesForServing(String servingTime) {
    if (activeDietData == null) return [];

    final cacheKey =
        '${DateFormat('yyyy-MM-dd').format(selectedDate.value)}|$servingTime';
    final cached = _recipesCache[cacheKey];
    if (cached != null) return cached;

    // week.dailyMeals now holds all 4 day-groups together in one response
    // (see getActiveDietPlanForPatient) - filter to the group the selected
    // date actually falls into, same mapping the backend used to apply
    // server-side per request.
    final dayGroup = resolveDayGroupForDate(selectedDate.value);
    final meals = activeDietData!.week.dailyMeals
        .where(
          (meal) =>
              meal.servingTime == servingTime &&
              _mealMatchesDayGroup(meal, dayGroup),
        )
        .toList();

    List<Recipe> recipes = [];

    for (var meal in meals) {
      final baseRecipe = activeDietData!.recipes[meal.recipeId];
      if (baseRecipe == null) continue;

      // meal.servings is the dietician-prescribed amount for this exact
      // occurrence (e.g. 3 for "3 chapatis", 400 for "400g Chole"); the
      // recipe map always holds the recipe's own unscaled base values, so
      // the ratio against its base servingSize.quantity is what scales
      // nutrition to match - same math as the dietician app's
      // _servingsRatio.
      final baseQuantity = baseRecipe.servingSize.quantity;
      final ratio = baseQuantity > 0 ? meal.servings / baseQuantity : 1;
      Recipe recipe = ratio == 1 ? baseRecipe : baseRecipe.scaledBy(ratio);

      // meal.componentServings (when present) is the dietician's actual
      // per-component quantities for this exact occurrence (e.g. Idli: 3
      // nos, Sambar: 1 bowl, Chutney: 2 tbsp) - absolute values, not a
      // ratio, so they replace the uniformly-scaled components above
      // outright rather than being multiplied by `ratio` again. Only
      // applied when it lines up 1:1 with the recipe's own components list;
      // otherwise (legacy meal, or recipe edited since this meal was last
      // saved) the uniform ratio scaling above is the best available
      // fallback - same as the backend's weekNutritionSummary.js.
      final overrides = meal.componentServings;
      if (overrides != null &&
          overrides.length == baseRecipe.components.length &&
          overrides.isNotEmpty) {
        recipe = recipe.withComponents(
          List.generate(baseRecipe.components.length, (i) {
            final base = baseRecipe.components[i];
            return RecipeComponent(
              label: base.label,
              quantity: overrides[i],
              unit: base.unit,
            );
          }),
        );
      }

      recipes.add(recipe);
    }

    _recipesCache[cacheKey] = recipes;
    return recipes;
  }

  Future<void> getLogMeal(DateTime? selectedDate) async {
    showLogMealLoading.value = true;

    final newLogMealDate = DateFormat(
      'yyyy-MM-dd',
    ).format(selectedDate ?? DateTime.now());

    // selectedPortions is keyed only by "servingTime-recipeId" (no date),
    // and DietController is a permanent singleton - so a portion picked
    // while viewing one day (this session or a previous, abandoned one)
    // would otherwise still be sitting in the map when a different day's
    // screen loads, ready to be silently included in *that* day's next
    // submit if the recipeId happens to repeat (see sendLogMeal). Only
    // clear on an actual day change, not every call (e.g. a same-day
    // refresh shouldn't discard picks still in progress).
    if (newLogMealDate != selectedLogMealDate.value) {
      selectedPortions.clear();
    }
    selectedLogMealDate.value = newLogMealDate;

    try {
      final response = await service.getLogMeal(selectedLogMealDate.value);

      if (response != null) {
        logMealData = LogMealData.fromJson(response['data']);
      }
    } catch (_) {}

    showLogMealLoading.value = false;
  }

  ServingTimeModel? getServingTimeByName(String servingTime) {
    if (logMealData == null) return null;

    try {
      return logMealData!.servingTimes.firstWhere(
        (e) => e.servingTime == servingTime,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> sendLogMeal() async {
    showSendLogMealLoading.value = true;

    // The day the Log Meal screen is actually showing - not "now". This
    // used to hardcode DateTime.now() here even though selectedLogMealDate
    // (set by getLogMeal, and shown in the sheet's own date chip) tracked
    // the real target day, so submitting for a previous day silently wrote
    // into *today's* MealLog instead - see getLogMeal above.
    final date = selectedLogMealDate.value.isNotEmpty
        ? selectedLogMealDate.value
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      List<Map<String, dynamic>> items = [];

      selectedPortions.forEach((key, portion) {
        final parts = key.split('-');
        final servingTime = parts[0];
        final recipeId = parts[1];

        // Find meal calories from logMealData
        final meal = logMealData!.servingTimes
            .firstWhere((s) => s.servingTime == servingTime)
            .plannedMeals
            .firstWhere((m) => m.recipeId == recipeId);

        items.add({
          "servingTime": servingTime,
          "recipeId": recipeId,
          "servings": portion,
          "caloriesConsumed": meal.calories * portion,
        });
      });

      if (items.isEmpty) {
        showSendLogMealLoading.value = false;
        return;
      }

      final int caloriesDelta = items.fold<int>(
        0,
        (sum, item) => sum + (item['caloriesConsumed'] as num).round(),
      );

      final data = {"date": date, "items": items};

      final response = await service.sendLogMeal(data, date);
      if (response != null) {
        if (response != null && response['success'] == true) {
          showAppToast(
            Get.overlayContext!,
            message: 'Meal log sent successfully!',
            type: AppToastType.success,
          );
          await Posthog().capture(
            eventName: 'meal_logged',
            properties: {'items_count': items.length, 'log_date': date},
          );
          // Logging is done - close the Log Meal sheet instead of leaving
          // the patient sitting on it.
          if (Get.isBottomSheetOpen == true) Get.back();
          // The Goal Journey card (Home) and its "Not logged"/"Logged" rows
          // (MilestoneSheet) both read off TimelineController's cached
          // /timeline data - without this they'd keep showing the meal as
          // unlogged until a socket event or the next full navigation
          // happened to refresh it.
          if (Get.isRegistered<TimelineController>()) {
            Get.find<TimelineController>().load(silent: true);
          }
          // Home's progress card owns its own copy of today's calorie/macro
          // totals (HomeController) - without this it kept showing
          // pre-log numbers until some unrelated trigger (app resume,
          // pull-to-refresh) happened to refetch it, regardless of whether
          // this meal was logged from the Progress tab, the Diet tab, or
          // Home's own Log Meal sheet.
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().applyOptimisticMealLog(caloriesDelta);
          }
        } else {
          showAppToast(
            Get.overlayContext!,
            message: 'Failed to send meal log.',
            type: AppToastType.error,
          );
        }
        selectedPortions.clear();
      }
    } catch (_) {}

    showSendLogMealLoading.value = false;
  }

  Rx<XFile?> pickedMyFoodImage = Rx<XFile?>(null);

  Future pickMyFoodImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedMyFoodImage.value = img;
    }
  }

  Future<void> createMyFood({
    required String date,
    required String servingTime,
    required String foodName,
    required String description,
    required String quantityLabel,
    required int portion,
  }) async {
    showCreateMealLoading.value = true;
    dio.MultipartFile? myFoodImage;

    if (pickedMyFoodImage.value != null) {
      myFoodImage = await dio.MultipartFile.fromFile(
        pickedMyFoodImage.value!.path,
        filename: pickedMyFoodImage.value!.name,
      );
    }

    debugPrint("-----------------$date");

    try {
      final formData = dio.FormData.fromMap({
        "date": date,
        "servingTime": servingTime,
        "foodName": foodName,
        "description": description,
        "quantityLabel": quantityLabel,
        "portion": portion,
        if (myFoodImage != null) "imageUrl": myFoodImage,
      });

      debugPrint("📤 CREATE MY FOOD PAYLOAD: ${formData.fields}");

      final response = await service.createMyFood(formData);

      if (response != null) {
        debugPrint("-----------------------> ${response['success']}");
        if (response['success'] == true) {
          Get.back();

          showAppToast(
            Get.overlayContext!,
            message: "Food added successfully",
            type: AppToastType.success,
          );
        } else {
          Get.back();

          showAppToast(
            Get.overlayContext!,
            message: "Failed to add food",
            type: AppToastType.error,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Create food error: $e');
      Get.back();
    }

    showCreateMealLoading.value = false;
  }
}
