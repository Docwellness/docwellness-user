import 'package:dio/dio.dart' as dio;
import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/app/models/log_meal_model.dart';
import 'package:docwellness/app/modules/diet/service/diet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DietController extends GetxController {
  final ImagePicker picker = ImagePicker();

  ActiveDietData? activeDietData;
  LogMealData? logMealData;
  final DietService service = DietService();
  RxMap<String, int> selectedPortions = <String, int>{}.obs;

  RxBool showActiveDietPlanLoading = false.obs;
  RxBool showLogMealLoading = false.obs;
  RxBool showSendLogMealLoading = false.obs;
  RxBool showCreateMealLoading = false.obs;

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

  DateTime get currentWeekStart =>
      _today.subtract(Duration(days: _today.weekday - 1));

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
    try {
      final effectiveDate = date ?? DateTime.now();
      selectedDate.value = effectiveDate;
      final dateStr = DateFormat('yyyy-MM-dd').format(effectiveDate);

      final response = await service.getActiveDiet(dateStr, week: week);

      if (response != null) {
        activeDietData = ActiveDietData.fromJson(response['data']);
        selectedWeek.value = activeDietData!.currentWeek;
        totalWeeks.value = activeDietData!.totalWeeks > 0
            ? activeDietData!.totalWeeks
            : 4;
      }
    } catch (_) {}
    showActiveDietPlanLoading.value = false;
  }

  void switchWeek(int week) {
    if (week != selectedWeek.value) {
      getActiveDiet(week: week);
    }
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
          Get.snackbar(
            'Success',
            'Meal log sent successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          );
          // Logging is done - close the Log Meal sheet instead of leaving
          // the patient sitting on it.
          if (Get.isBottomSheetOpen == true) Get.back();
        } else {
          Get.snackbar(
            'Error',
            'Failed to send meal log.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
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

          Get.snackbar(
            "Success",
            "Food added successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white,
          );
        } else {
          Get.back();

          Get.snackbar(
            "Error",
            "Failed to add food",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade600,
            colorText: Colors.white,
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
