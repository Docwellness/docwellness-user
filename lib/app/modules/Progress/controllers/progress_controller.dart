import 'package:dio/dio.dart' as dio;
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/models/journey_image_model.dart';
import 'package:docwellness/app/models/tracking_data_model.dart';
import 'package:docwellness/main.dart' as main_app;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  RxString selectedPeriod = 'week'.obs;

  // Tracking data (model-based)
  RxList<BmiDataPoint> bmiTrend = <BmiDataPoint>[].obs;
  RxList<WeightDataPoint> weightTrend = <WeightDataPoint>[].obs;
  RxList<CalorieDataPoint> calorieData = <CalorieDataPoint>[].obs;
  RxInt currentIndex = 0.obs;
  RxInt plannedDailyCalories = 0.obs;
  RxString activityLevel = ''.obs;
  RxList<String> healthConcerns = <String>[].obs;
  Rx<DateRangeLabel?> dateRange = Rx<DateRangeLabel?>(null);

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
      fetchTrackingData(),
      fetchJourneyImages(),
      fetchAutoJourneyMilestones(),
      fetchDoctorNotes(),
      fetchTodayMealStats(),
    ]);
  }

  Future<void> refreshAll() async {
    await fetchAllData();
  }

  /// Change the selected period and re-fetch tracking data
  void changePeriod(String period) {
    selectedPeriod.value = period;
    fetchTrackingData();
  }

  String get periodLabel {
    switch (selectedPeriod.value) {
      case 'week':
        return 'This week';
      case 'month':
        return 'This month';
      case 'year':
        return 'This year';
      default:
        return 'This week';
    }
  }

  /// Fetch all tracking data from single endpoint
  Future<void> fetchTrackingData() async {
    isStatsLoading.value = true;
    try {
      final d = dio.Dio();
      final response = await d.get(
        '${AppConfig.patientApiBaseUrl}/tracking-data',
        queryParameters: {'period': selectedPeriod.value},
        options: dio.Options(
          headers: {'Authorization': 'Bearer ${main_app.token}'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final raw = response.data['data'];
        final tracking = TrackingData.fromJson(
          raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw ?? {}),
        );

        currentWeight.value = tracking.currentWeight;
        currentBMI.value = tracking.currentBmi;
        currentIndex.value = tracking.currentIndex;
        plannedDailyCalories.value = tracking.plannedDailyCalories;
        targetWeight.value = tracking.targetWeight;
        activityLevel.value = tracking.activityLevel;
        healthConcerns.value = tracking.healthConcerns;
        dateRange.value = tracking.dateRange;

        calorieData.value = tracking.calorieData;
        weightTrend.value = tracking.weightTrend;
        bmiTrend.value = tracking.bmiTrend;

        // Derive start weight from first non-zero weight point
        final firstWeight = tracking.weightTrend
            .where((w) => w.weight > 0)
            .toList();
        if (firstWeight.isNotEmpty) {
          startWeight.value = firstWeight.first.weight;
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

        // Body measurements
        armMeasurement.value = tracking.bodyMeasurements.arm;
        waistMeasurement.value = tracking.bodyMeasurements.waist;
        hipMeasurement.value = tracking.bodyMeasurements.hip;

        // Achievements
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
      }
    } catch (e, s) {
      debugPrint('Error fetching tracking data: $e');
      debugPrintStack(stackTrace: s);
    } finally {
      isStatsLoading.value = false;
    }
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
      Get.snackbar(
        'Error',
        'Please enter a value',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (selectParameter.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a parameter',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final weight = double.tryParse(valueController.text.trim());
      if (weight == null) {
        Get.snackbar(
          'Error',
          'Please enter a valid number',
          snackPosition: SnackPosition.BOTTOM,
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
        fetchTrackingData();

        return true;
      } else {
        Get.snackbar(
          'Error',
          response.data['message'] ?? 'Submission failed',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error submitting body data: $e');
      Get.snackbar(
        'Error',
        'Failed to submit body data',
        snackPosition: SnackPosition.BOTTOM,
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
      Get.snackbar(
        'Error',
        'Please select at least one image',
        snackPosition: SnackPosition.BOTTOM,
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
        Get.snackbar(
          'Error',
          response.data['message'] ?? 'Upload failed',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading journey image: $e');
      Get.snackbar(
        'Error',
        'Failed to upload image',
        snackPosition: SnackPosition.BOTTOM,
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
