import 'package:dio/dio.dart' as dio;
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/models/journey_image_model.dart';
import 'package:docwellness/app/models/tracking_data_model.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/main.dart' as main_app;
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class ProgressController extends GetxController {
  final ImagePicker picker = ImagePicker();

  RxString selectLogBodyDay = "".obs;
  RxString selectParameter = "".obs;
  Rx<XFile?> pickedBeforeImage = Rx<XFile?>(null);
  Rx<XFile?> pickedAfterImage = Rx<XFile?>(null);
  Rx<XFile?> pickedBodyImage = Rx<XFile?>(null);
  Rx<XFile?> pickedBodyImage2 = Rx<XFile?>(null);

  // Journey images list (manual uploads)
  RxList<JourneyImageModel> journeyImages = <JourneyImageModel>[].obs;
  // Auto-generated milestone journey cards
  RxList<JourneyImageModel> autoJourneyCards = <JourneyImageModel>[].obs;
  RxBool isJourneyLoading = false.obs;
  RxBool isSubmitting = false.obs;

  // Doctor notes / feedback
  RxList<Map<String, dynamic>> doctorNotes = <Map<String, dynamic>>[].obs;
  RxBool isDoctorNotesLoading = false.obs;

  // === Tracking Data (from /tracking-data API) ===
  RxBool isStatsLoading = false.obs;
  RxDouble currentWeight = 0.0.obs;
  RxDouble startWeight = 0.0.obs;
  RxDouble targetWeight = 0.0.obs;
  RxDouble currentBMI = 0.0.obs;
  RxDouble weightChange = 0.0.obs;
  RxDouble percentageChange = 0.0.obs;
  RxInt totalEntries = 0.obs;
  RxDouble averageAdherence = 0.0.obs;

  // Each chart on the Progress screen (Calorie Intake, Weight Trend, BMI)
  // has its own independent date range selector instead of a fixed week/
  // month/year period - null until the first fetch for that chart resolves
  // and reports back the actual [start, end] it applied (defaults to
  // [dietStartDate, today] - see ProgressController.fetchAllTrackingData).
  Rx<DateTime?> dietStartDate = Rx<DateTime?>(null);
  Rx<DateTime?> calorieRangeStart = Rx<DateTime?>(null);
  Rx<DateTime?> calorieRangeEnd = Rx<DateTime?>(null);
  Rx<DateTime?> weightRangeStart = Rx<DateTime?>(null);
  Rx<DateTime?> weightRangeEnd = Rx<DateTime?>(null);
  Rx<DateTime?> bmiRangeStart = Rx<DateTime?>(null);
  Rx<DateTime?> bmiRangeEnd = Rx<DateTime?>(null);

  // Tracking data (model-based)
  RxList<BmiDataPoint> bmiTrend = <BmiDataPoint>[].obs;
  RxList<WeightDataPoint> weightTrend = <WeightDataPoint>[].obs;
  RxList<CalorieDataPoint> calorieData = <CalorieDataPoint>[].obs;
  RxInt calorieCurrentIndex = 0.obs;
  RxInt weightCurrentIndex = 0.obs;
  RxInt bmiCurrentIndex = 0.obs;
  RxInt plannedDailyCalories = 0.obs;
  RxString activityLevel = ''.obs;
  RxList<String> healthConcerns = <String>[].obs;
  Rx<DateRangeLabel?> calorieDateRange = Rx<DateRangeLabel?>(null);
  Rx<DateRangeLabel?> weightDateRange = Rx<DateRangeLabel?>(null);
  Rx<DateRangeLabel?> bmiDateRange = Rx<DateRangeLabel?>(null);

  // === Body Measurements ===
  RxDouble armMeasurement = 0.0.obs;
  RxDouble waistMeasurement = 0.0.obs;
  RxDouble hipMeasurement = 0.0.obs;

  // === Achievements (from API) ===
  RxList<Map<String, String>> achievements = <Map<String, String>>[].obs;

  // === Today's meal stats ===
  RxInt todayCalories = 0.obs;
  RxInt todayMealsLogged = 0.obs;
  RxInt todayMealsPlanned = 3.obs;

  // Text controllers for the log body form
  final TextEditingController valueController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController armController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    await Future.wait([
      fetchAllTrackingData(),
      fetchJourneyImages(),
      fetchAutoJourneyMilestones(),
      fetchDoctorNotes(),
      fetchTodayMealStats(),
    ]);
  }

  Future<void> refreshAll() async {
    await fetchAllData();
  }

  /// Change the Calorie Intake chart's date range and re-fetch just its data.
  void changeCalorieRange(DateTimeRange range) {
    calorieRangeStart.value = range.start;
    calorieRangeEnd.value = range.end;
    fetchCalorieTrackingData();
  }

  /// Change the Weight Trend chart's date range and re-fetch just its data.
  void changeWeightRange(DateTimeRange range) {
    weightRangeStart.value = range.start;
    weightRangeEnd.value = range.end;
    fetchWeightTrackingData();
  }

  /// Change the BMI chart's date range and re-fetch just its data.
  void changeBmiRange(DateTimeRange range) {
    bmiRangeStart.value = range.start;
    bmiRangeEnd.value = range.end;
    fetchBmiTrackingData();
  }

  /// Fetch calorie, weight, and BMI tracking data in parallel - each chart
  /// keeps its own date range, so this hits the shared /tracking-data
  /// endpoint once per chart with that chart's selected range.
  Future<void> fetchAllTrackingData() async {
    isStatsLoading.value = true;
    try {
      await Future.wait([
        fetchCalorieTrackingData(),
        fetchWeightTrackingData(),
        fetchBmiTrackingData(),
      ]);
    } finally {
      isStatsLoading.value = false;
    }
  }

  static final DateFormat _queryDateFormat = DateFormat('yyyy-MM-dd');

  /// Shared GET /tracking-data call - returns null on any failure. Omitting
  /// start/end lets the backend default to [plan start, today] (the first
  /// call for each chart, before the patient has picked a custom range).
  Future<TrackingData?> _fetchTrackingData(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final d = dio.Dio();
      final response = await d.get(
        '${AppConfig.patientApiBaseUrl}/tracking-data',
        queryParameters: {
          if (startDate != null) 'startDate': _queryDateFormat.format(startDate),
          if (endDate != null) 'endDate': _queryDateFormat.format(endDate),
        },
        options: dio.Options(
          headers: {'Authorization': 'Bearer ${main_app.token}'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final raw = response.data['data'];
        return TrackingData.fromJson(
          raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw ?? {}),
        );
      }
    } catch (e, s) {
      debugPrint('Error fetching tracking data: $e');
      debugPrintStack(stackTrace: s);
    }
    return null;
  }

  /// Calorie Intake chart data + the page-wide stats that ride along with it
  /// (planned calories, achievements - these aren't range-specific server
  /// side, so whichever call populates them first is fine).
  Future<void> fetchCalorieTrackingData() async {
    final tracking = await _fetchTrackingData(
      calorieRangeStart.value,
      calorieRangeEnd.value,
    );
    if (tracking == null) return;

    calorieData.value = tracking.calorieData;
    calorieCurrentIndex.value = tracking.currentIndex;
    calorieDateRange.value = tracking.dateRange;
    plannedDailyCalories.value = tracking.plannedDailyCalories;
    achievements.value = tracking.achievements
        .map(
          (a) => {
            'type': a.type,
            'title': a.title,
            'description': a.description,
            'icon': a.icon,
          },
        )
        .toList();
    dietStartDate.value ??= tracking.planStartDate;
    calorieRangeStart.value =
        tracking.appliedStartDate ?? calorieRangeStart.value ?? DateTime.now();
    calorieRangeEnd.value =
        tracking.appliedEndDate ?? calorieRangeEnd.value ?? DateTime.now();
  }

  /// Weight Trend chart data, plus the current/target/start weight stats
  /// that are naturally computed from the same weight log.
  Future<void> fetchWeightTrackingData() async {
    final tracking = await _fetchTrackingData(
      weightRangeStart.value,
      weightRangeEnd.value,
    );
    if (tracking == null) return;

    weightTrend.value = tracking.weightTrend;
    weightCurrentIndex.value = tracking.currentIndex;
    weightDateRange.value = tracking.dateRange;
    currentWeight.value = tracking.currentWeight;
    targetWeight.value = tracking.targetWeight;
    activityLevel.value = tracking.activityLevel;
    healthConcerns.value = tracking.healthConcerns;
    armMeasurement.value = tracking.bodyMeasurements.arm;
    waistMeasurement.value = tracking.bodyMeasurements.waist;
    hipMeasurement.value = tracking.bodyMeasurements.hip;
    dietStartDate.value ??= tracking.planStartDate;
    weightRangeStart.value =
        tracking.appliedStartDate ?? weightRangeStart.value ?? DateTime.now();
    weightRangeEnd.value =
        tracking.appliedEndDate ?? weightRangeEnd.value ?? DateTime.now();

    // Before the diet plan actually starts there's no real "initial vs
    // current" progress to show - weightTrend's first point is just
    // whatever the range curve happens to land on, not a real starting
    // weigh-in for THIS plan. Showing it as "Initial weight" next to a
    // different "Current weight" implies progress that hasn't actually
    // happened yet (see HomeController's dietEnabled - same gate used for
    // the subscription banner and the Log Meal/Log Body Data buttons).
    final dietStarted =
        Get.isRegistered<HomeController>() &&
        Get.find<HomeController>().dietEnabled.value;

    if (!dietStarted) {
      startWeight.value = currentWeight.value;
      weightChange.value = 0;
      percentageChange.value = 0;
      return;
    }

    // "Initial weight" is a fact about the whole plan, not about whichever
    // window the chart currently happens to be showing - only re-derive it
    // when the fetched range actually reaches back to the plan's real
    // start (planStartDate). A narrower, user-picked range (e.g. "just the
    // last 2 weeks") must not overwrite it with that window's own first
    // point, which isn't the plan's real starting weight.
    final coversFullHistory =
        tracking.planStartDate != null &&
        tracking.appliedStartDate != null &&
        !tracking.appliedStartDate!.isAfter(tracking.planStartDate!);
    if (coversFullHistory) {
      final firstWeight = tracking.weightTrend
          .where((w) => w.weight > 0)
          .toList();
      if (firstWeight.isNotEmpty) {
        startWeight.value = firstWeight.first.weight;
      }
    }

    // Calculate weight change
    if (currentWeight.value > 0 && startWeight.value > 0) {
      weightChange.value = currentWeight.value - startWeight.value;
    }

    // Calculate percentage toward target
    if (targetWeight.value > 0 && startWeight.value > 0) {
      final totalGoalDiff = (targetWeight.value - startWeight.value).abs();
      if (totalGoalDiff > 0) {
        percentageChange.value =
            (weightChange.value.abs() / totalGoalDiff * 100).clamp(0, 999);
      }
    }
  }

  /// BMI chart data - BMI is derived from the same weight log, on its own
  /// independently-selected date range.
  Future<void> fetchBmiTrackingData() async {
    final tracking = await _fetchTrackingData(
      bmiRangeStart.value,
      bmiRangeEnd.value,
    );
    if (tracking == null) return;

    bmiTrend.value = tracking.bmiTrend;
    bmiCurrentIndex.value = tracking.currentIndex;
    bmiDateRange.value = tracking.dateRange;
    currentBMI.value = tracking.currentBmi;
    dietStartDate.value ??= tracking.planStartDate;
    bmiRangeStart.value =
        tracking.appliedStartDate ?? bmiRangeStart.value ?? DateTime.now();
    bmiRangeEnd.value =
        tracking.appliedEndDate ?? bmiRangeEnd.value ?? DateTime.now();
  }

  /// Fetch today's meal log stats (calories, meals logged)
  Future<void> fetchTodayMealStats() async {
    try {
      final d = dio.Dio();
      final response = await d.get(
        '${AppConfig.patientApiBaseUrl}/meal-logs/stats',
        options: dio.Options(
          headers: {'Authorization': 'Bearer ${main_app.token}'},
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        todayCalories.value =
            (data['totalCalories'] ?? data['totalConsumedCalories'] ?? 0)
                as int;
        todayMealsLogged.value =
            (data['mealsLogged'] ?? data['loggedMeals'] ?? 0) as int;
        todayMealsPlanned.value =
            (data['mealsPlanned'] ?? data['totalMeals'] ?? 3) as int;
      }
    } catch (e) {
      debugPrint('Error fetching meal stats: $e');
    }
  }

  @override
  void onClose() {
    valueController.dispose();
    descriptionController.dispose();
    armController.dispose();
    waistController.dispose();
    hipController.dispose();
    super.onClose();
  }

  void setLogBodyDay(String value) {
    selectLogBodyDay.value = value;
  }

  void setParametery(String value) {
    selectParameter.value = value;
  }

  Future pickBeforeImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedBeforeImage.value = img;
    }
  }

  Future pickAfterImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedAfterImage.value = img;
    }
  }

  Future pickBodyImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedBodyImage.value = img;
    }
  }

  Future pickBodyImage2() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedBodyImage2.value = img;
    }
  }

  /// Submit body data (weight/parameter) to progress API
  Future<bool> submitBodyData() async {
    if (valueController.text.trim().isEmpty) {
      showAppToast(
        Get.overlayContext!,
        message: 'Please enter a value',
        type: AppToastType.error,
      );
      return false;
    }

    if (selectParameter.value.isEmpty) {
      showAppToast(
        Get.overlayContext!,
        message: 'Please select a parameter',
        type: AppToastType.error,
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final weight = double.tryParse(valueController.text.trim());
      if (weight == null) {
        showAppToast(
          Get.overlayContext!,
          message: 'Please enter a valid number',
          type: AppToastType.error,
        );
        isSubmitting.value = false;
        return false;
      }

      final map = <String, dynamic>{
        'weight': weight,
        'notes': descriptionController.text,
        'date': DateTime.now().toIso8601String(),
      };

      // Add body measurements if provided
      final armVal = double.tryParse(armController.text.trim());
      final waistVal = double.tryParse(waistController.text.trim());
      final hipVal = double.tryParse(hipController.text.trim());
      if (armVal != null && armVal > 0) map['arm'] = armVal;
      if (waistVal != null && waistVal > 0) map['waist'] = waistVal;
      if (hipVal != null && hipVal > 0) map['hip'] = hipVal;

      if (pickedBodyImage.value != null) {
        map['bodyImage'] = await dio.MultipartFile.fromFile(
          pickedBodyImage.value!.path,
          filename: pickedBodyImage.value!.name,
        );
      }

      if (pickedBodyImage2.value != null) {
        map['bodyImage2'] = await dio.MultipartFile.fromFile(
          pickedBodyImage2.value!.path,
          filename: pickedBodyImage2.value!.name,
        );
      }

      final formData = dio.FormData.fromMap(map);

      final d = dio.Dio();
      final response = await d.post(
        '${AppConfig.patientApiBaseUrl}/progress',
        data: formData,
        options: dio.Options(
          headers: {'Authorization': 'Bearer ${main_app.token}'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        await Posthog().capture(
          eventName: 'body_data_logged',
          properties: {
            'parameter': selectParameter.value,
            'has_body_image': pickedBodyImage.value != null,
            'has_measurements': armController.text.isNotEmpty ||
                waistController.text.isNotEmpty ||
                hipController.text.isNotEmpty,
          },
        );
        // Reset form
        pickedBodyImage.value = null;
        pickedBodyImage2.value = null;
        valueController.clear();
        descriptionController.clear();
        armController.clear();
        waistController.clear();
        hipController.clear();
        selectLogBodyDay.value = '';
        selectParameter.value = '';

        // Refresh auto-journey milestones (body image feeds into journey)
        fetchAutoJourneyMilestones();
        // Refresh tracking data with new data
        fetchAllTrackingData();

        return true;
      } else {
        showAppToast(
          Get.overlayContext!,
          message: response.data['message'] ?? 'Submission failed',
          type: AppToastType.error,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error submitting body data: $e');
      showAppToast(
        Get.overlayContext!,
        message: 'Failed to submit body data',
        type: AppToastType.error,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Fetch all journey images from API
  Future<void> fetchJourneyImages() async {
    isJourneyLoading.value = true;
    try {
      final d = dio.Dio();
      final response = await d.get(
        '${AppConfig.patientApiBaseUrl}/journey',
        options: dio.Options(
          headers: {'Authorization': 'Bearer ${main_app.token}'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        journeyImages.value = data
            .map((e) => JourneyImageModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching journey images: $e');
    } finally {
      isJourneyLoading.value = false;
    }
  }

  /// Submit journey image to API
  Future<bool> submitJourneyImage() async {
    if (pickedBeforeImage.value == null && pickedAfterImage.value == null) {
      showAppToast(
        Get.overlayContext!,
        message: 'Please select at least one image',
        type: AppToastType.error,
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final map = <String, dynamic>{
        'dayLabel': selectLogBodyDay.value.isNotEmpty
            ? 'Day ${selectLogBodyDay.value}'
            : 'Day 1',
        'description': descriptionController.text,
      };

      if (pickedBeforeImage.value != null) {
        map['beforeImage'] = await dio.MultipartFile.fromFile(
          pickedBeforeImage.value!.path,
          filename: pickedBeforeImage.value!.name,
        );
      }
      if (pickedAfterImage.value != null) {
        map['afterImage'] = await dio.MultipartFile.fromFile(
          pickedAfterImage.value!.path,
          filename: pickedAfterImage.value!.name,
        );
      }

      final formData = dio.FormData.fromMap(map);

      final d = dio.Dio();
      final response = await d.post(
        '${AppConfig.patientApiBaseUrl}/journey',
        data: formData,
        options: dio.Options(
          headers: {'Authorization': 'Bearer ${main_app.token}'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        // Reset form
        pickedBeforeImage.value = null;
        pickedAfterImage.value = null;
        valueController.clear();
        descriptionController.clear();
        selectLogBodyDay.value = '';
        selectParameter.value = '';

        // Refresh journey images
        await fetchJourneyImages();
        return true;
      } else {
        showAppToast(
          Get.overlayContext!,
          message: response.data['message'] ?? 'Upload failed',
          type: AppToastType.error,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading journey image: $e');
      showAppToast(
        Get.overlayContext!,
        message: 'Failed to upload image',
        type: AppToastType.error,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Fetch auto-generated milestone journey cards from body log images.
  /// The backend computes: before = first-ever body log image, after = closest
  /// image to each milestone day (Day 1, 7, 14, 30, 60, 90 + latest).
  Future<void> fetchAutoJourneyMilestones() async {
    try {
      final d = dio.Dio();
      final response = await d.get(
        '${AppConfig.patientApiBaseUrl}/journey/milestones',
        options: dio.Options(
          headers: {'Authorization': 'Bearer ${main_app.token}'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List milestones = data['milestones'] ?? [];
        final List manual = data['manualImages'] ?? [];

        // Convert milestones to JourneyImageModel for UI compatibility
        final List<JourneyImageModel> cards = milestones.map<JourneyImageModel>(
          (m) {
            return JourneyImageModel(
              id: 'auto_${m['dayNumber']}',
              patientId: '',
              dieticianId: '',
              uploadedBy: '',
              uploadedByRole: 'auto',
              beforeImageUrl: m['beforeImageUrl'] ?? '',
              afterImageUrl: m['afterImageUrl'] ?? '',
              description: m['description'] ?? '',
              dayLabel: m['dayLabel'] ?? 'Day 1',
              createdAt: m['date'] != null
                  ? DateTime.parse(m['date'].toString())
                  : DateTime.now(),
              updatedAt: DateTime.now(),
            );
          },
        ).toList();

        // Append any manual journey images at the end
        for (final m in manual) {
          cards.add(JourneyImageModel.fromJson(m));
        }

        autoJourneyCards.value = cards;
      }
    } catch (e) {
      debugPrint('Error fetching auto journey milestones: $e');
    }
  }

  /// Fetch doctor notes sent to this patient
  Future<void> fetchDoctorNotes() async {
    isDoctorNotesLoading.value = true;
    try {
      final d = dio.Dio();
      final response = await d.get(
        '${AppConfig.patientApiBaseUrl}/doctor-notes',
        options: dio.Options(
          headers: {'Authorization': 'Bearer ${main_app.token}'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        doctorNotes.value = data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching doctor notes: $e');
    } finally {
      isDoctorNotesLoading.value = false;
    }
  }
}
