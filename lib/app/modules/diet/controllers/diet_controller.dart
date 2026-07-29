import 'package:dio/dio.dart' as dio;
import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/app/models/log_meal_model.dart';
import 'package:docwellness/app/modules/diet/service/diet_service.dart';
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
      return DateTime(planWeekStart.year, planWeekStart.month, planWeekStart.day);
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
  /// isDateInCurrentWeek for the selectable range.
  void switchDate(DateTime date) {
    if (!isDateInCurrentWeek(date)) return;
    getActiveDiet(date: date);
  }

  /// Recipes tagged 'supplement' across every serving-time slot for the
  /// currently selected day, de-duped by recipe id - powers the dedicated
  /// Supplements tab, since a supplement otherwise sits anonymously (with
  /// zeroed macros) inside whatever real servingTime slot it was assigned
  /// to, easy for a patient to miss entirely.
  List<Recipe> getSupplementRecipes() {
    if (activeDietData == null) return [];
    final seen = <String>{};
    final result = <Recipe>[];
    for (final meal in activeDietData!.week.dailyMeals) {
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

    final meals = activeDietData!.week.dailyMeals
        .where((meal) => meal.servingTime == servingTime)
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
      recipes.add(ratio == 1 ? baseRecipe : baseRecipe.scaledBy(ratio));
    }

    _recipesCache[cacheKey] = recipes;
    return recipes;
  }

  Future<void> getLogMeal(DateTime? selectedDate) async {
    showLogMealLoading.value = true;

    selectedLogMealDate.value = DateFormat(
      'yyyy-MM-dd',
    ).format(selectedDate ?? DateTime.now());

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

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
            properties: {
              'items_count': items.length,
              'log_date': date,
            },
          );
          // Logging is done - close the Log Meal sheet instead of leaving
          // the patient sitting on it.
          if (Get.isBottomSheetOpen == true) Get.back();
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
