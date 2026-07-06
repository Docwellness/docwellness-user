import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' as dio;
import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/app/models/my_food_model.dart';
import 'package:docwellness/app/modules/Progress/controllers/progress_controller.dart';
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/diet/service/diet_service.dart';
import 'package:docwellness/app/modules/grocery/controllers/grocery_controller.dart';
import 'package:docwellness/app/modules/home/services/doctor_profile_service.dart';
import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/app/modules/home/widgets/request_diet_plan.view.dart';
import 'package:docwellness/app/modules/notifications/services/notification_service.dart';
import 'package:docwellness/app/modules/profile/controllers/profile_controller.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  RxInt selectedIndex = 0.obs;
  RxString selectedGender = "".obs;
  RxString selectedHeight = "".obs;
  final RxSet<int> savedSet = <int>{}.obs;
  RxString selectedPortionFromLogMealSheet = "".obs;
  RxList<MyFoodModel> myFoodsList = <MyFoodModel>[].obs;

  bool isSaved(int id) => savedSet.contains(id);

  final ImagePicker picker = ImagePicker();
  RxBool paymentInfoSending = false.obs;

  // Subscription
  static const double subscriptionAmount = 2500;

  // Coupon state
  TextEditingController couponCodeController = TextEditingController();
  RxString appliedCouponCode = ''.obs;
  RxDouble appliedDiscount = 0.0.obs;
  RxBool isCouponValidating = false.obs;
  RxString couponMessage = ''.obs;
  RxBool couponSuccess = false.obs;

  // Computed amounts after coupon
  RxDouble discountValue = 0.0.obs;
  RxDouble finalAmount = subscriptionAmount.obs;

  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  StreamSubscription? _notifSub;
  static const int _refreshIntervalSeconds = 30; // Refresh every 30 seconds
  int _consecutiveErrors = 0; // Track consecutive API failures for backoff

  // Request diet
  RxBool isSendRequestLoading = false.obs;

  // Request status tracking
  RxBool isLoadingRequestStatus = false.obs;
  RxBool hasRequest = false.obs;
  RxString requestStatus =
      ''.obs; // Unpaid, PaymentRequested, PaymentSubmitted, Paid
  RxString requestId = ''.obs;
  RxDouble latestAmountReceived = 0.0.obs;
  RxDouble latestAmountPending = 0.0.obs;

  // Subscription expiry
  Rx<DateTime?> subscriptionStartDate = Rx<DateTime?>(null);
  Rx<DateTime?> subscriptionExpiresAt = Rx<DateTime?>(null);

  bool get isSubscriptionExpired {
    if (subscriptionExpiresAt.value == null) return false;
    return DateTime.now().isAfter(subscriptionExpiresAt.value!);
  }

  int get daysRemaining {
    if (subscriptionExpiresAt.value == null) return 0;
    final diff = subscriptionExpiresAt.value!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  RxBool isRequestDietPlanLoading = false.obs;
  RxString userName = ''.obs;
  TextEditingController requestUserName = TextEditingController();
  TextEditingController requestUserDob = TextEditingController();
  TextEditingController requestUserWeight = TextEditingController();
  TextEditingController requestUserStartDate = TextEditingController();

  TextEditingController pendingAmount = TextEditingController();
  TextEditingController totalAmount = TextEditingController(
    text: subscriptionAmount.toInt().toString(),
  );
  TextEditingController paymentDes = TextEditingController();
  RxInt bmiIndex = 0.obs;
  RxDouble bmiValue = 0.0.obs;
  RxString activityLevel = ''.obs;
  RxString targetedWeight = ''.obs;
  RxList<String> illness = <String>[].obs;

  //

  Rx<XFile?> pickedPaymentImage = Rx<XFile?>(null);

  // Progress card data
  RxBool hasProgressData = false.obs;
  RxInt progressIntake = 0.obs;
  RxInt progressRemaining = 0.obs;
  RxInt progressExercise = 0.obs;
  RxInt progressTotalPlanned = 0.obs;
  RxInt carbsConsumed = 0.obs;
  RxInt carbsPlanned = 0.obs;
  RxInt proteinConsumed = 0.obs;
  RxInt proteinPlanned = 0.obs;
  RxInt fiberConsumed = 0.obs;
  RxInt fiberPlanned = 0.obs;
  RxInt fatConsumed = 0.obs;
  RxInt fatPlanned = 0.obs;

  // Doctor profile
  Rx<DoctorProfileModel?> doctorProfile = Rx<DoctorProfileModel?>(null);

  // Notification badge count
  final NotificationService _notifService = NotificationService();
  RxInt notificationUnreadCount = 0.obs;

  // Chat unread badge count
  RxInt chatUnreadCount = 0.obs;
  StreamSubscription? _messageSub;

  // Date navigation for progress card
  Rx<DateTime> selectedDate = DateTime.now().obs;
  Rx<DateTime?> planStartDate = Rx<DateTime?>(null);
  Rx<DateTime?> planEndDate = Rx<DateTime?>(null);

  String get selectedDateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );
    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (selected == today.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('dd MMM yyyy').format(selectedDate.value);
  }

  bool get canGoBack {
    if (planStartDate.value == null) return false;
    final prev = selectedDate.value.subtract(const Duration(days: 1));
    final start = DateTime(
      planStartDate.value!.year,
      planStartDate.value!.month,
      planStartDate.value!.day,
    );
    return !prev.isBefore(start);
  }

  bool get canGoForward {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = selectedDate.value.add(const Duration(days: 1));
    final nextDay = DateTime(next.year, next.month, next.day);
    // Don't allow going beyond today
    if (nextDay.isAfter(today)) return false;
    // Don't allow going beyond plan end date
    if (planEndDate.value == null) return false;
    final end = DateTime(
      planEndDate.value!.year,
      planEndDate.value!.month,
      planEndDate.value!.day,
    );
    return !nextDay.isAfter(end);
  }

  void changeDate(int daysDelta) {
    if (daysDelta < 0 && !canGoBack) return;
    if (daysDelta > 0 && !canGoForward) return;
    selectedDate.value = selectedDate.value.add(Duration(days: daysDelta));
    fetchTodayStats();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void onInit() {
    super.onInit();
    // Load cached request status immediately so UI shows correct button
    _loadCachedRequestStatus();
    // Defer network calls to after the first frame renders,
    // preventing ANR on startup
    Future.delayed(const Duration(milliseconds: 500), () {
      // Guard against orphan timers: if controller was disposed
      // before this delayed callback fires, bail out
      if (isClosed) return;
      fetchUserName();
      fetchRequestStatus();
      fetchTodayStats();
      fetchDoctorProfile();
      fetchNotificationCount();
      fetchChatUnreadCount();
      _startAutoRefresh();
      _listenForNotifications();
      _listenForMessages();
    });
  }

  /// Load cached request status from SharedPreferences for instant UI
  void _loadCachedRequestStatus() async {
    final pref = await SharedPreferences.getInstance();
    final cachedStatus = pref.getString('cachedRequestStatus') ?? '';
    final cachedHasRequest = pref.getBool('cachedHasRequest') ?? false;
    if (cachedHasRequest && cachedStatus.isNotEmpty) {
      hasRequest.value = cachedHasRequest;
      requestStatus.value = cachedStatus;
      requestId.value = pref.getString('requestId') ?? '';
    }
  }

  void _listenForNotifications() {
    try {
      final socket = Get.find<SocketService>();
      _notifSub = socket.onNotification.listen((_) {
        notificationUnreadCount.value++;
      });
    } catch (_) {
      debugPrint('⚠️ SocketService not available for notifications');
    }
  }

  /// Listen for incoming messages to update chat badge live
  void _listenForMessages() {
    try {
      final socket = Get.find<SocketService>();
      _messageSub = socket.onMessage.listen((data) {
        // Skip ACKs (our own sent messages)
        if (data['type'] == 'ack') return;
        chatUnreadCount.value++;
      });
    } catch (_) {
      debugPrint('⚠️ SocketService not available for messages');
    }
  }

  /// Fetch initial chat unread count from conversations API
  Future<void> fetchChatUnreadCount() async {
    try {
      final chatService = ChatService();
      final conversations = await chatService.getConversations();
      int total = 0;
      for (final conv in conversations) {
        total += conv.unreadCount;
      }
      chatUnreadCount.value = total;
    } catch (e) {
      debugPrint('Error fetching chat unread count: $e');
    }
  }

  Future<void> fetchUserName() async {
    final RequestDietService service = RequestDietService();
    try {
      final response = await service.getUserInfo();
      if (response != null && response['data'] != null) {
        final profile = response['data']['profile'] ?? {};
        final fullName = profile['fullName']?.toString() ?? '';
        if (fullName.isNotEmpty) {
          userName.value = fullName.split(' ').first;
        }

        // Load health profile for BMI card
        final healthProfile = response['data']['healthProfile'] ?? {};
        debugPrint('🏥 healthProfile from API: $healthProfile');

        final bmi = healthProfile['bmi'];
        if (bmi != null) {
          bmiValue.value = (bmi as num).toDouble();
        } else {
          // Calculate BMI from weight/height if bmi field is missing
          final w = healthProfile['weight'];
          final h = healthProfile['height'];
          if (w != null && h != null) {
            final weight = (w as num).toDouble();
            final height = (h as num).toDouble();
            if (weight > 0 && height > 0) {
              final heightM = height / 100;
              bmiValue.value = double.parse(
                (weight / (heightM * heightM)).toStringAsFixed(1),
              );
            }
          }
        }

        final weightIndex = healthProfile['weightIndex'];
        if (weightIndex != null) {
          bmiIndex.value = weightIndex;
        } else if (bmiValue.value > 0) {
          // Derive bmiIndex from BMI value if not provided
          if (bmiValue.value < 18.5) {
            bmiIndex.value = 1; // Underweight
          } else if (bmiValue.value < 25) {
            bmiIndex.value = 0; // Normal
          } else if (bmiValue.value < 30) {
            bmiIndex.value = 2; // Overweight
          } else {
            bmiIndex.value = 3; // Obese
          }
        }

        final targetWeight = healthProfile['targetWeight'];
        if (targetWeight != null) {
          targetedWeight.value = targetWeight.toString();
        }

        final activity = healthProfile['activityLevel'];
        if (activity != null) {
          activityLevel.value = activity.toString();
        }

        final list = healthProfile['healthConcerns'];
        if (list != null) {
          illness.value = List<String>.from(list.map((e) => e.toString()));
        }
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
  }

  @override
  void onClose() {
    _stopAutoRefresh();
    _notifSub?.cancel();
    _messageSub?.cancel();
    super.onClose();
  }

  /// Start auto-refresh timer for request status
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (_) => _silentRefreshStatus(),
    );
  }

  /// Stop auto-refresh timer
  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Silent refresh without showing loading indicator
  Future<void> _silentRefreshStatus() async {
    // Guard: stop if controller was disposed (orphan timer)
    if (isClosed) {
      _stopAutoRefresh();
      return;
    }
    // Stop polling for terminal/stable states
    final currentStatus = requestStatus.value;
    if (currentStatus == 'Paid' || currentStatus == 'Unpaid') {
      _stopAutoRefresh();
      return;
    }
    final RequestDietService service = RequestDietService();
    try {
      final response = await service.getRequestStatus();
      if (response != null && response['data'] != null) {
        _consecutiveErrors = 0; // Reset on success
        final data = response['data'];
        hasRequest.value = data['hasRequest'] ?? false;
        final newStatus = data['status'] ?? '';
        final summary = data['paymentSummary'];
        latestAmountReceived.value =
            (summary != null && summary['amountReceived'] is num)
            ? (summary['amountReceived'] as num).toDouble()
            : 0;
        latestAmountPending.value =
            (summary != null && summary['amountPending'] is num)
            ? (summary['amountPending'] as num).toDouble()
            : 0;

        // Only update if status changed
        if (requestStatus.value != newStatus) {
          requestStatus.value = newStatus;
          requestId.value = data['requestId']?.toString() ?? '';
          debugPrint('📡 Status Updated: $newStatus');
          // Stop polling for terminal/stable states
          if (newStatus == 'Paid' || newStatus == 'Unpaid') {
            _stopAutoRefresh();
          }
        }
      }
    } catch (e) {
      _consecutiveErrors++;
      debugPrint('Silent refresh error ($_consecutiveErrors): $e');
      // Back off: stop polling after 3 consecutive failures
      if (_consecutiveErrors >= 3) {
        debugPrint('⚠️ Too many consecutive errors, stopping auto-refresh');
        _stopAutoRefresh();
      }
    }
  }

  /// Fetch the current request status from the backend
  Future<void> fetchRequestStatus() async {
    isLoadingRequestStatus.value = true;
    final RequestDietService service = RequestDietService();
    try {
      final response = await service.getRequestStatus();
      if (response != null && response['data'] != null) {
        final data = response['data'];
        hasRequest.value = data['hasRequest'] ?? false;
        requestStatus.value = data['status'] ?? '';
        requestId.value = data['requestId']?.toString() ?? '';
        final summary = data['paymentSummary'];
        latestAmountReceived.value =
            (summary != null && summary['amountReceived'] is num)
            ? (summary['amountReceived'] as num).toDouble()
            : 0;
        latestAmountPending.value =
            (summary != null && summary['amountPending'] is num)
            ? (summary['amountPending'] as num).toDouble()
            : 0;

        // Parse subscription dates
        if (data['subscriptionStartDate'] != null) {
          subscriptionStartDate.value = DateTime.tryParse(
            data['subscriptionStartDate'].toString(),
          );
        }
        if (data['subscriptionExpiresAt'] != null) {
          subscriptionExpiresAt.value = DateTime.tryParse(
            data['subscriptionExpiresAt'].toString(),
          );
        }

        // Cache status locally for instant UI on next controller init
        final pref = await SharedPreferences.getInstance();
        pref.setBool('cachedHasRequest', hasRequest.value);
        pref.setString('cachedRequestStatus', requestStatus.value);
        if (requestId.value.isNotEmpty) {
          pref.setString('requestId', requestId.value);
        }

        debugPrint('📡 Request Status: ${requestStatus.value}');
      }
    } catch (e) {
      debugPrint('Error fetching request status: $e');
    }
    isLoadingRequestStatus.value = false;
  }

  /// Comprehensive refresh - refreshes all home data
  Future<void> refreshAllData() async {
    debugPrint('🔄 Refreshing all data...');
    // Reset error counter on manual refresh so polling can resume
    _consecutiveErrors = 0;
    await Future.wait([
      fetchRequestStatus(),
      fetchTodayStats(),
      fetchDoctorProfile(),
      fetchNotificationCount(),
      fetchChatUnreadCount(),
    ]);
    // Restart auto-refresh if it was stopped (user might have regained connectivity)
    final status = requestStatus.value;
    if (status != 'Paid' && status != 'Unpaid' && _autoRefreshTimer == null) {
      _startAutoRefresh();
    }
    debugPrint('✅ Data refresh complete');
  }

  /// Fetch assigned doctor profile
  Future<void> fetchDoctorProfile() async {
    final DoctorProfileService service = DoctorProfileService();
    try {
      final profile = await service.getAssignedDoctorProfile();
      if (profile != null) {
        doctorProfile.value = profile;
      }
    } catch (e) {
      debugPrint('❌ Error fetching doctor profile: $e');
    }
  }

  Future<void> fetchNotificationCount() async {
    notificationUnreadCount.value = await _notifService.getUnreadCount();
  }

  /// Fetch meal log stats for the selected date
  Future<void> fetchTodayStats() async {
    final DietService dietService = DietService();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final response = await dietService.getTodayMealLogStats(date: dateStr);
      if (response != null && response['data'] != null) {
        final data = response['data'];

        // Update plan boundaries
        if (data['planStartDate'] != null) {
          planStartDate.value = DateTime.parse(data['planStartDate']);
        }
        if (data['planEndDate'] != null) {
          planEndDate.value = DateTime.parse(data['planEndDate']);
        }

        final summary = data['summary'] ?? {};
        final macros = data['macros'] ?? {};
        final consumed = macros['consumed'] ?? {};
        final planned = macros['planned'] ?? {};

        progressIntake.value = (summary['totalConsumedCalories'] ?? 0) as int;
        progressRemaining.value = (summary['remainingCalories'] ?? 0) as int;
        progressTotalPlanned.value =
            (summary['totalPlannedCalories'] ?? 0) as int;
        progressExercise.value = 0; // Exercise tracking not yet implemented

        carbsConsumed.value = (consumed['carbs'] ?? 0) as int;
        carbsPlanned.value = (planned['carbs'] ?? 0) as int;
        proteinConsumed.value = (consumed['protein'] ?? 0) as int;
        proteinPlanned.value = (planned['protein'] ?? 0) as int;
        fiberConsumed.value = (consumed['fiber'] ?? 0) as int;
        fiberPlanned.value = (planned['fiber'] ?? 0) as int;
        fatConsumed.value = (consumed['fats'] ?? 0) as int;
        fatPlanned.value = (planned['fats'] ?? 0) as int;

        hasProgressData.value = true;
      } else {
        hasProgressData.value = false;
      }
    } catch (e) {
      debugPrint('❌ fetchTodayStats error: $e');
      hasProgressData.value = false;
    }
  }

  Future pickPaymentImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedPaymentImage.value = img;
    }
    log("Payment Image Path: ${pickedPaymentImage.value!.path}");
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void onTabSelected(int index) {
    switch (index) {
      case 1:
        if (!Get.isRegistered<ProgressController>()) {
          Get.put(ProgressController());
        }
        break;
      case 2:
        if (Get.isRegistered<DietController>()) {
          Get.find<DietController>().getActiveDiet();
        } else {
          Get.put(DietController());
        }
        break;
      case 3:
        if (!Get.isRegistered<GroceryController>()) {
          Get.put(GroceryController());
        }
        break;
      case 4:
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
        break;
    }
  }

  void setGender(String value) {
    selectedGender.value = value;
  }

  void toggleSave(int id) {
    if (savedSet.contains(id)) {
      savedSet.remove(id);
    } else {
      savedSet.add(id);
    }
  }

  Future<void> getRequestUserInfo() async {
    isRequestDietPlanLoading.value = true;
    final RequestDietService service = RequestDietService();
    try {
      debugPrint('📡 Fetching user info...');
      final response = await service.getUserInfo();
      debugPrint('📡 Response: $response');

      if (response != null) {
        String dob = '';

        final profile = response['data']?['profile'] ?? {};
        final healthProfile = response['data']?['healthProfile'] ?? {};
        debugPrint('📡 Profile: $profile');
        debugPrint('📡 HealthProfile: $healthProfile');

        final rawDate = profile['dateOfBirth'];

        if (rawDate != null && rawDate.toString().isNotEmpty) {
          final date = DateTime.parse(rawDate);
          dob =
              "${date.day.toString().padLeft(2, '0')}/"
              "${date.month.toString().padLeft(2, '0')}/"
              "${date.year}";
        }

        requestUserName = TextEditingController(
          text: profile['fullName']?.toString() ?? '',
        );
        selectedGender.value = profile['gender']?.toString() ?? '';

        final height = healthProfile['height'];
        if (height != null) {
          selectedHeight.value = "$height CM";
        }

        requestUserDob = TextEditingController(text: dob);

        final weight = healthProfile['weight'];
        if (weight != null) {
          requestUserWeight = TextEditingController(
            text: "${weight.toString()} Kg",
          );
        }

        final weightIndex = healthProfile['weightIndex'];
        if (weightIndex != null) {
          bmiIndex.value = weightIndex;
        }

        final bmi = healthProfile['bmi'];
        if (bmi != null) {
          bmiValue.value = (bmi as num).toDouble();
        }

        final targetWeight = healthProfile['targetWeight'];
        if (targetWeight != null) {
          targetedWeight.value = targetWeight;
        }

        final activity = healthProfile['activityLevel'];
        if (activity != null) {
          activityLevel.value = activity.toString();
        }

        final list = healthProfile['healthConcerns'];
        if (list != null) {
          illness.value = List<String>.from(list.map((e) => e.toString()));
        }
      }
    } catch (e) {
      debugPrint('-------------------> $e');
    }
    isRequestDietPlanLoading.value = false;
  }

  double calculateBMI() {
    final weightText = requestUserWeight.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    final heightText = selectedHeight.value.replaceAll(RegExp(r'[^0-9.]'), '');

    final weight = double.tryParse(weightText) ?? 0;
    final heightCm = double.tryParse(heightText) ?? 0;

    if (weight <= 0 || heightCm <= 0) return 0;

    final heightM = heightCm / 100;
    final bmiValue = weight / (heightM * heightM);

    return double.parse(bmiValue.toStringAsFixed(1));
  }

  void updateBMI() {
    bmiValue.value = calculateBMI();

    if (bmiValue.value < 18.5) {
      bmiIndex.value = 1;
    } else if (bmiValue.value >= 18.5 && bmiValue.value < 25) {
      bmiIndex.value = 0;
    } else if (bmiValue.value >= 25 && bmiValue.value < 30) {
      bmiIndex.value = 1;
    } else {
      bmiIndex.value = 2;
    }
  }

  Future<void> sendRequestDietPlan() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    isSendRequestLoading.value = true;
    final weightText = requestUserWeight.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    final heightText = selectedHeight.replaceAll(RegExp(r'[^0-9.]'), '');

    String formatDateForApi(String dateStr) {
      if (dateStr.isEmpty) return '';
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      return dateStr;
    }

    final RequestDietService service = RequestDietService();
    final data = {
      'startDateForDiet': formatDateForApi(requestUserStartDate.text.trim()),
      'fullName': requestUserName.text.trim(),
      'dateOfBirth': formatDateForApi(requestUserDob.text.trim()),
      'gender': selectedGender.value,
      'weight': weightText,
      'height': heightText,
      'bmi': bmiValue.value,
      'weightIndex': bmiIndex.value,
    };

    try {
      log('---------> $data');
      final response = await service.sendRequestDietPlan(data);
      if (response != null) {
        pref.setString('requestId', response['data']['requestId']);
        log('------------> ${response['success']}');
        // Immediately update local state so home screen shows correct button
        hasRequest.value = true;
        requestStatus.value = 'Unpaid';
        requestId.value = response['data']['requestId']?.toString() ?? '';
        // Cache status so new controller instances also show correct state
        pref.setBool('cachedHasRequest', true);
        pref.setString('cachedRequestStatus', 'Unpaid');
        // Navigate to Connect for Payment screen
        Get.off(() => const RequestDietPlanScreen());
      } else {
        Get.snackbar('Error', 'Failed to submit request. Please try again.');
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
      Get.snackbar('Error', 'Something went wrong. Please try again.');
    }
    isSendRequestLoading.value = false;
  }

  Future<void> sendPaymentInfo() async {
    paymentInfoSending.value = true;

    final SharedPreferences pref = await SharedPreferences.getInstance();
    final RequestDietService service = RequestDietService();

    dio.MultipartFile? proofMultipart;

    if (pickedPaymentImage.value != null) {
      proofMultipart = await dio.MultipartFile.fromFile(
        pickedPaymentImage.value!.path,
        filename: pickedPaymentImage.value!.name,
      );
    }

    // Use the stored requestId, or fall back to the reactive one
    String? storedRequestId = pref.getString('requestId');
    if (storedRequestId == null || storedRequestId.isEmpty) {
      storedRequestId = requestId.value;
    }

    if (storedRequestId.isEmpty) {
      Get.snackbar(
        'Error',
        'No request ID found. Please refresh and try again.',
      );
      paymentInfoSending.value = false;
      return;
    }

    final data = <String, dynamic>{
      'requestId': storedRequestId,
      'amountReceived': totalAmount.text.trim(),
      'amountPending': pendingAmount.text.trim(),
      'description': paymentDes.text.trim(),
    };

    // Attach coupon info if applied
    if (appliedCouponCode.value.isNotEmpty) {
      data['couponCode'] = appliedCouponCode.value;
      data['discountPercentage'] = appliedDiscount.value.toString();
      data['originalAmount'] = subscriptionAmount.toInt().toString();
    }

    // Only add proofImage if user picked one
    if (proofMultipart != null) {
      data['proofImage'] = proofMultipart;
    }

    log('------------> $data');

    try {
      final response = await service.sendPaymentInfo(data);

      if (response != null) {
        log('------------> ${response['success']}');
        Get.back();
        Get.snackbar(
          'Success',
          'Payment details sent successfully. Please wait for dietician review.',
        );

        // Send payment notification in chat
        try {
          final paidAmt = pendingAmount.text.trim().isNotEmpty
              ? pendingAmount.text.trim()
              : latestAmountPending.value % 1 == 0
              ? latestAmountPending.value.toInt().toString()
              : latestAmountPending.value.toStringAsFixed(2);
          final socket = Get.find<SocketService>();
          socket.sendMessageV1(
            conversationId: '',
            receiverId: '',
            clientMessageId: 'payment_${DateTime.now().millisecondsSinceEpoch}',
            content:
                '💳 Payment Submitted\n'
                '₹$paidAmt has been paid.\n'
                'Awaiting dietician confirmation.',
            type: 'text',
          );
        } catch (_) {}

        // Refresh the request status
        await fetchRequestStatus();
        // Clear the form
        pickedPaymentImage.value = null;
        totalAmount.text = subscriptionAmount.toInt().toString();
        pendingAmount.clear();
        paymentDes.clear();
        removeCoupon();
      } else {
        Get.snackbar(
          'Error',
          'Failed to send payment details. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('------------> $e');
      Get.snackbar('Error', 'Something went wrong. Please try again.');
    }

    paymentInfoSending.value = false;
  }

  Future<void> validateAndApplyCoupon() async {
    final code = couponCodeController.text.trim();
    if (code.isEmpty) {
      couponMessage.value = 'Please enter a coupon code';
      couponSuccess.value = false;
      return;
    }

    isCouponValidating.value = true;
    couponMessage.value = '';

    final RequestDietService service = RequestDietService();
    final response = await service.validateCoupon(code);

    if (response != null && response['success'] == true) {
      final data = response['data'];
      appliedCouponCode.value = data['code'] ?? code;
      appliedDiscount.value =
          (data['discountPercentage'] as num?)?.toDouble() ?? 0;
      couponMessage.value =
          '${data['name'] ?? 'Coupon'} applied! ${appliedDiscount.value.toInt()}% off';
      couponSuccess.value = true;
      _recalculateAmounts();
    } else {
      appliedCouponCode.value = '';
      appliedDiscount.value = 0;
      couponMessage.value =
          response?['message'] ?? 'Invalid or expired coupon code';
      couponSuccess.value = false;
    }

    isCouponValidating.value = false;
  }

  void removeCoupon() {
    couponCodeController.clear();
    appliedCouponCode.value = '';
    appliedDiscount.value = 0;
    couponMessage.value = '';
    couponSuccess.value = false;
    _recalculateAmounts();
  }

  void _recalculateAmounts() {
    if (appliedDiscount.value > 0) {
      discountValue.value = (subscriptionAmount * appliedDiscount.value) / 100;
      finalAmount.value = subscriptionAmount - discountValue.value;
    } else {
      discountValue.value = 0;
      finalAmount.value = subscriptionAmount;
    }
    totalAmount.text = finalAmount.value.toInt().toString();
    pendingAmount.text = '0';
  }
}
