import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/app/models/my_food_model.dart';
import 'package:docwellness/app/modules/Progress/controllers/progress_controller.dart';
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/diet/service/diet_service.dart';
import 'package:docwellness/app/modules/grocery/controllers/grocery_controller.dart';
import 'package:docwellness/app/modules/home/services/doctor_profile_service.dart';
import 'package:docwellness/app/modules/home/services/first_consultation_service.dart';
import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/app/modules/home/widgets/request_diet_plan.view.dart';
import 'package:docwellness/app/modules/notifications/services/notification_service.dart';
import 'package:docwellness/app/modules/profile/controllers/profile_controller.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/app/services/connectivity_service.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  RxInt selectedIndex = 0.obs;
  RxString selectedGender = "".obs;
  final RxSet<int> savedSet = <int>{}.obs;
  RxString selectedPortionFromLogMealSheet = "".obs;
  RxList<MyFoodModel> myFoodsList = <MyFoodModel>[].obs;

  bool isSaved(int id) => savedSet.contains(id);

  final ImagePicker picker = ImagePicker();
  RxBool paymentInfoSending = false.obs;

  // Subscription - amount/name reflect whichever membership plan the user
  // picked on the Connect for Payment screen (see selectPlan()).
  RxString selectedPlanName = 'Silver Membership'.obs;
  RxDouble selectedPlanAmount = 2500.0.obs;

  // Coupon state
  TextEditingController couponCodeController = TextEditingController();
  RxString appliedCouponCode = ''.obs;
  RxDouble appliedDiscount = 0.0.obs;
  RxBool isCouponValidating = false.obs;
  RxString couponMessage = ''.obs;
  RxBool couponSuccess = false.obs;

  // Computed amounts after coupon
  RxDouble discountValue = 0.0.obs;
  RxDouble finalAmount = 2500.0.obs;

  /// Called when the user picks a membership plan on the Connect for
  /// Payment screen - updates the amount used throughout the payment-proof
  /// flow (originalAmount, finalAmount, coupon discount math), and persists
  /// the choice onto the diet plan request itself so it survives refreshes
  /// and is what Order Summary reads back.
  Future<void> selectPlan({required String name, required double amount}) async {
    selectedPlanName.value = name;
    selectedPlanAmount.value = amount;
    _recalculateAmounts();

    if (requestId.value.isEmpty) return;
    final RequestDietService service = RequestDietService();
    await service.selectMembershipPlan(
      requestId: requestId.value,
      membershipPlan: name,
      membershipAmount: amount,
    );
  }

  /// Starts a renewal cycle on the existing (already-activated) diet plan
  /// request - resets its payment/status fields on the backend so the
  /// patient can pick a plan again without redoing the full intake form
  /// (their consultation/personal data already exists). Call this before
  /// navigating to RequestDietPlanScreen for a renewal.
  Future<void> startRenewal() async {
    if (requestId.value.isEmpty) return;
    final RequestDietService service = RequestDietService();
    await service.startRenewal(requestId: requestId.value);
    await fetchRequestStatus();
  }

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

  // Whether the dietician has filled in a first consultation for this
  // patient yet - gates the "View First Consultation" button.
  RxBool hasFirstConsultation = false.obs;

  // Whether the patient has already submitted consent on that first
  // consultation - once true, the "View First Consultation" button is
  // replaced by a "diet plan is being prepared" message on Home.
  RxBool firstConsultationConsented = false.obs;

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
  TextEditingController requestUserHeight = TextEditingController();
  TextEditingController requestUserStartDate = TextEditingController();
  TextEditingController requestTargetWeight = TextEditingController();

  // The only amount the patient actually types - how much they've paid.
  // Defaults to the full amount owed (most patients pay in full); editing
  // it down is how a partial payment gets recorded - see
  // recalculateRemainingAmount below for how "Remaining" is derived from it.
  TextEditingController paidAmountController = TextEditingController(
    text: '2500', // matches selectedPlanAmount's default (Silver)
  );
  // Auto-derived, never typed directly - amount owed minus paidAmountController.
  RxDouble remainingAmount = 0.0.obs;
  // Only shown/required when remainingAmount > 0.
  TextEditingController pendingPaymentDateController = TextEditingController();
  // Mandatory-fields gate for "Send Payment Details" - proof image, a
  // positive paid amount, and (only when something's left owing) the
  // pending-payment date. Re-evaluated on every input that could change it;
  // see _evaluateCanSubmitPayment's call sites.
  RxBool canSubmitPayment = false.obs;

  void _evaluateCanSubmitPayment() {
    final paid = double.tryParse(paidAmountController.text.trim()) ?? 0;
    canSubmitPayment.value =
        pickedPaymentImage.value != null &&
        paid > 0 &&
        (remainingAmount.value <= 0 ||
            pendingPaymentDateController.text.trim().isNotEmpty);
  }
  RxInt bmiIndex = 0.obs;
  RxDouble bmiValue = 0.0.obs;
  RxString activityLevel = ''.obs;
  RxString targetedWeight = ''.obs;
  RxList<String> illness = <String>[].obs;
  RxString selectedGoal = ''.obs;

  //

  Rx<XFile?> pickedPaymentImage = Rx<XFile?>(null);
  // Read once when picked (see pickPaymentImage below) and reused for both
  // the in-screen preview (Image.memory) and the actual upload
  // (MultipartFile.fromBytes) - same fix as chat_service.dart's
  // uploadImage/sendMealNote: XFile.path is only a blob: URL on Flutter
  // Web, not a real filesystem path, so both Image.file(File(path)) and
  // MultipartFile.fromFile(path) silently fail there. readAsBytes() works
  // on every platform.
  Rx<Uint8List?> pickedPaymentImageBytes = Rx<Uint8List?>(null);

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

  // Whether the patient's diet plan has actually started yet - drives Home's
  // BMI/timer card, hiding the water log, and gating "Log Meal" (issue: a
  // patient shouldn't be able to log meals against a diet that hasn't
  // unlocked, or that doesn't exist yet). True is the optimistic default so
  // Home doesn't flash a gated state before the first check completes -
  // _refreshDietGate corrects it as soon as DietController's data is in.
  RxBool dietEnabled = true.obs;
  RxBool hasDietPlan = false.obs;
  // Non-null only while dietEnabled is false and a plan with a future start
  // date exists - null (no plan yet at all) means "not enabled, no timer to
  // show".
  Rx<DateTime?> dietStartsAt = Rx<DateTime?>(null);

  /// Reads DietController's already-fetched (or freshly-fetched) active
  /// diet plan - DietController stays the single owner of that data
  /// (lazily registered, see main.dart), this just derives Home's simpler
  /// enabled/disabled + countdown view of it.
  Future<void> _refreshDietGate() async {
    if (!Get.isRegistered<DietController>()) {
      dietEnabled.value = false;
      hasDietPlan.value = false;
      dietStartsAt.value = null;
      return;
    }
    final diet = Get.find<DietController>();
    if (diet.activeDietData == null) {
      await diet.getActiveDiet();
    }
    final data = diet.activeDietData;
    final startDate = data?.weekStartDate;
    final enabled = data != null && (startDate == null || !startDate.isAfter(DateTime.now()));
    hasDietPlan.value = data != null;
    dietEnabled.value = enabled;
    dietStartsAt.value = enabled ? null : startDate;
  }

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
    // DatePickerField (custom_datepicker.dart) has no onChange hook of its
    // own - it just writes straight into the controller when a date is
    // picked, so this is the only way to catch that and re-evaluate the
    // Send Payment Details button's mandatory-fields gate.
    pendingPaymentDateController.addListener(_evaluateCanSubmitPayment);
    // HomeController is permanent (survives the whole app session, see
    // resetForFreshLogin's doc comment above) so this listener effectively
    // covers "refresh when the connection comes back" regardless of which
    // tab/screen is currently showing.
    Get.find<ConnectivityService>().registerOnReconnected(refreshAllData);
    Get.find<ConnectivityService>().registerOnReconnected(_notifyBackOnline);
    // Load cached request status immediately so UI shows correct button
    _loadCachedRequestStatus();
    // Defer network calls to after the first frame renders,
    // preventing ANR on startup
    Future.delayed(const Duration(milliseconds: 500), () {
      // Guard against orphan timers: if controller was disposed
      // before this delayed callback fires, bail out
      if (isClosed) return;
      // silent: true - this is the cold-start burst of ~6 concurrent
      // requests; one losing the race to open a socket shouldn't pop a "No
      // Internet" dialog over an otherwise-successful Home load.
      _loadAllData(silent: true);
      _startAutoRefresh();
      _listenForNotifications();
      _listenForMessages();
    });
  }

  void _loadAllData({bool silent = false}) {
    fetchUserName(silent: silent);
    fetchRequestStatus(silent: silent);
    fetchFirstConsultationExists(silent: silent);
    fetchTodayStats(silent: silent);
    fetchDoctorProfile(silent: silent);
    fetchNotificationCount(silent: silent);
    fetchChatUnreadCount();
    _refreshDietGate();
  }

  /// Call right after a successful login/signup. HomeController is
  /// registered `permanent: true` (see HomeBinding) so it survives logout →
  /// login instead of being recreated - meaning onInit's fetch burst above
  /// only ever runs once per app session. Without this, re-logging in (same
  /// user, or a different one on a shared browser) landed on Home still
  /// showing whichever tab and stale data were left over from the previous
  /// session instead of the current user's fresh data, fetched immediately.
  void resetForFreshLogin() {
    selectedIndex.value = 0;
    selectedDate.value = DateTime.now();
    _loadAllData(silent: true);
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

  Future<void> fetchUserName({bool silent = false}) async {
    final RequestDietService service = RequestDietService();
    try {
      final response = await service.getUserInfo(silent: silent);
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

        final goal = healthProfile['primaryGoal'];
        if (goal != null) {
          selectedGoal.value = goal.toString();
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
    Get.find<ConnectivityService>().unregister(refreshAllData);
    Get.find<ConnectivityService>().unregister(_notifyBackOnline);
    _stopAutoRefresh();
    _notifSub?.cancel();
    _messageSub?.cancel();
    super.onClose();
  }

  /// Resting/stable states that never change on their own - 'PartiallyPaid'
  /// is activated (like 'Paid') just with a balance still owed; the patient
  /// (or dietician) has to take an explicit action (send/submit a payment)
  /// to move off it, so it's not worth polling for either.
  bool _isTerminalStatus(String status) =>
      status == 'Paid' || status == 'Unpaid' || status == 'PartiallyPaid';

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
    if (_isTerminalStatus(currentStatus)) {
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
          if (_isTerminalStatus(newStatus)) {
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
  Future<void> fetchRequestStatus({bool silent = false}) async {
    isLoadingRequestStatus.value = true;
    final RequestDietService service = RequestDietService();
    try {
      final response = await service.getRequestStatus(silent: silent);
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

        // Keep the Payment Status sheet's "Subscription Amount" in sync
        // with whatever plan is actually on the request - this endpoint
        // already returns it, but until now only fetchRequestDetails()
        // (Order Summary only) applied it, so opening Payment Status
        // without having visited Order Summary first left selectedPlanAmount
        // stuck at its hardcoded default (2500/Silver) regardless of the
        // patient's real membership plan.
        if (data['membershipPlan'] != null && data['membershipAmount'] is num) {
          selectedPlanName.value = data['membershipPlan'].toString();
          selectedPlanAmount.value = (data['membershipAmount'] as num)
              .toDouble();
          _recalculateFinalAmount();
        }

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

  /// Whether the dietician has filled in a first consultation yet - controls
  /// visibility of the "View First Consultation" button.
  Future<void> fetchFirstConsultationExists({bool silent = false}) async {
    try {
      final response = await FirstConsultationService().getMyConsultation(
        silent: silent,
      );
      final data = response != null ? response['data'] : null;
      hasFirstConsultation.value = data != null;
      if (data != null) {
        final customAnswers = (data['customAnswers'] as List?) ?? [];
        final consentAnswer = customAnswers.firstWhere(
          (a) => (a['fieldId'] ?? '').toString() == 'consent_acknowledgement',
          orElse: () => null,
        );
        final consentValue = consentAnswer != null ? consentAnswer['value'] : null;
        firstConsultationConsented.value =
            consentValue is List && consentValue.contains('I consent');
      } else {
        firstConsultationConsented.value = false;
      }
    } catch (e) {
      debugPrint('Error fetching first consultation: $e');
    }
  }

  /// Full snapshot of the latest diet plan request - personal info exactly
  /// as submitted with it (not the potentially-since-changed patient
  /// profile), the start date, and the selected membership plan. Used by
  /// Order Summary; kept separate from the lightweight fetchRequestStatus()
  /// (which polls every 30s for the home button state) so that frequent
  /// polling doesn't also re-populate these display fields.
  Future<void> fetchRequestDetails() async {
    isRequestDietPlanLoading.value = true;
    final RequestDietService service = RequestDietService();
    try {
      final response = await service.getRequestStatus();
      final data = response?['data'];
      if (data != null && data['hasRequest'] == true) {
        String formatDate(String? raw) {
          if (raw == null || raw.isEmpty) return '';
          var parsed = DateTime.tryParse(raw);
          if (parsed == null) {
            // Some older records stored a raw JS `Date.toString()` value
            // (e.g. "Fri Jul 02 2010 02:00:00 GMT+0200 (Central European
            // Summer Time)") instead of an ISO date string, which
            // DateTime.tryParse can't handle. Fall back to pulling the
            // day/month/year out of that format directly.
            const months = {
              'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
              'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
            };
            final match = RegExp(
              r'^\w{3} (\w{3}) (\d{2}) (\d{4})',
            ).firstMatch(raw);
            if (match != null && months.containsKey(match.group(1))) {
              parsed = DateTime(
                int.parse(match.group(3)!),
                months[match.group(1)]!,
                int.parse(match.group(2)!),
              );
            }
          }
          if (parsed == null) return '';
          return "${parsed.day.toString().padLeft(2, '0')}/"
              "${parsed.month.toString().padLeft(2, '0')}/"
              "${parsed.year}";
        }

        requestUserStartDate = TextEditingController(
          text: formatDate(data['startDateForDiet']?.toString()),
        );
        requestUserName = TextEditingController(
          text: data['fullName']?.toString() ?? '',
        );
        requestUserDob = TextEditingController(
          text: formatDate(data['dateOfBirth']?.toString()),
        );
        selectedGender.value = data['gender']?.toString() ?? '';
        requestUserWeight = TextEditingController(
          text: data['weight'] != null ? data['weight'].toString() : '',
        );
        requestUserHeight = TextEditingController(
          text: data['height'] != null ? data['height'].toString() : '',
        );

        if (data['bmi'] is num) {
          bmiValue.value = (data['bmi'] as num).toDouble();
        }
        if (data['weightIndex'] is num) {
          bmiIndex.value = (data['weightIndex'] as num).toInt();
        }
        targetedWeight.value = data['targetWeight']?.toString() ?? '';
        activityLevel.value = data['activityLevel']?.toString() ?? '';
        selectedGoal.value = data['primaryGoal']?.toString() ?? '';
        if (data['healthConcerns'] is List) {
          illness.value = List<String>.from(
            (data['healthConcerns'] as List).map((e) => e.toString()),
          );
        }

        if (data['membershipPlan'] != null &&
            data['membershipAmount'] is num) {
          selectedPlanName.value = data['membershipPlan'].toString();
          selectedPlanAmount.value = (data['membershipAmount'] as num)
              .toDouble();
          _recalculateFinalAmount();
        }
      }
    } catch (e) {
      debugPrint('Error fetching request details: $e');
    }
    isRequestDietPlanLoading.value = false;
  }

  /// Comprehensive refresh - refreshes all home data
  /// Separate from refreshAllData - that's also called from Home's manual
  /// pull-to-refresh, where a "Back online" toast would be a lie (or at
  /// least noise) since connectivity never actually changed.
  void _notifyBackOnline() {
    final ctx = Get.overlayContext;
    if (ctx == null) return;
    showAppToast(ctx, message: 'Back online', type: AppToastType.success);
  }

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
      _refreshDietGate(),
    ]);
    // Restart auto-refresh if it was stopped (user might have regained connectivity)
    final status = requestStatus.value;
    if (!_isTerminalStatus(status) && _autoRefreshTimer == null) {
      _startAutoRefresh();
    }
    debugPrint('✅ Data refresh complete');
  }

  /// Fetch assigned doctor profile
  Future<void> fetchDoctorProfile({bool silent = false}) async {
    final DoctorProfileService service = DoctorProfileService();
    try {
      final profile = await service.getAssignedDoctorProfile(silent: silent);
      if (profile != null) {
        doctorProfile.value = profile;
      }
    } catch (e) {
      debugPrint('❌ Error fetching doctor profile: $e');
    }
  }

  Future<void> fetchNotificationCount({bool silent = false}) async {
    notificationUnreadCount.value = await _notifService.getUnreadCount(
      silent: silent,
    );
  }

  // The backend rounds these at the API boundary, but scaled-nutrition
  // fields have crashed a bare `as int` cast before (a fractional value like
  // a serving-ratio-scaled macro throws instead of casting) - round
  // defensively here too rather than assume every number is always a whole
  // int by the time it arrives.
  int _toInt(dynamic value) => value is num ? value.round() : 0;

  /// Fetch meal log stats for the selected date
  Future<void> fetchTodayStats({bool silent = false}) async {
    final DietService dietService = DietService();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final response = await dietService.getTodayMealLogStats(
        date: dateStr,
        silent: silent,
      );
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

        progressIntake.value = _toInt(summary['totalConsumedCalories']);
        progressRemaining.value = _toInt(summary['remainingCalories']);
        progressTotalPlanned.value = _toInt(summary['totalPlannedCalories']);
        progressExercise.value = 0; // Exercise tracking not yet implemented

        carbsConsumed.value = _toInt(consumed['carbs']);
        carbsPlanned.value = _toInt(planned['carbs']);
        proteinConsumed.value = _toInt(consumed['protein']);
        proteinPlanned.value = _toInt(planned['protein']);
        fiberConsumed.value = _toInt(consumed['fiber']);
        fiberPlanned.value = _toInt(planned['fiber']);
        fatConsumed.value = _toInt(consumed['fats']);
        fatPlanned.value = _toInt(planned['fats']);

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
      pickedPaymentImageBytes.value = await img.readAsBytes();
      _evaluateCanSubmitPayment();
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
          requestUserHeight = TextEditingController(text: height.toString());
        }

        requestUserDob = TextEditingController(text: dob);

        final weight = healthProfile['weight'];
        if (weight != null) {
          requestUserWeight = TextEditingController(text: weight.toString());
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
          requestTargetWeight = TextEditingController(
            text: targetWeight.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
          );
        }

        final activity = healthProfile['activityLevel'];
        if (activity != null) {
          activityLevel.value = activity.toString();
        }

        final goal = healthProfile['primaryGoal'];
        if (goal != null) {
          selectedGoal.value = goal.toString();
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
    final heightText = requestUserHeight.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );

    final weight = double.tryParse(weightText) ?? 0;
    final heightCm = double.tryParse(heightText) ?? 0;

    if (weight <= 0 || heightCm <= 0) return 0;

    final heightM = heightCm / 100;
    final bmiValue = weight / (heightM * heightM);

    return double.parse(bmiValue.toStringAsFixed(1));
  }

  // Index scheme must match BmiContainer: 0=Normal, 1=Underweight,
  // 2=Overweight, 3=Obese (same mapping used in getRequestUserInfo's
  // fallback above) - this previously mapped Overweight to 1 (Underweight's
  // slot) and Obese to 2 (Overweight's slot), which is what made the BMI
  // label flip to "Underweight" after editing weight into the 25-30 range.
  void updateBMI() {
    bmiValue.value = calculateBMI();

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

  // Keeps the "Target Weight" row in the BMI card (which reads
  // targetedWeight.value directly, already " kg"-suffixed to match the
  // format AuthController.setTargetWeight uses at signup) in sync with the
  // editable field on the Request Diet Plan screen.
  void updateTargetWeight() {
    final digits = requestTargetWeight.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    targetedWeight.value = digits.isEmpty ? '' : '$digits kg';
  }

  Future<void> sendRequestDietPlan() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    isSendRequestLoading.value = true;
    final weightText = requestUserWeight.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    final heightText = requestUserHeight.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );

    String formatDateForApi(String dateStr) {
      if (dateStr.isEmpty) return '';
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
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
      'targetWeight': targetedWeight.value,
      'activityLevel': activityLevel.value,
      'healthConcerns': illness.toList(),
      'primaryGoal': selectedGoal.value,
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
        await Posthog().capture(
          eventName: 'diet_plan_requested',
          properties: {
            'primary_goal': selectedGoal.value,
            'activity_level': activityLevel.value,
          },
        );
        // Navigate to Connect for Payment screen
        Get.off(() => const RequestDietPlanScreen());
      } else {
        showAppToast(
          Get.overlayContext!,
          message: 'Failed to submit request. Please try again.',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
      showAppToast(
        Get.overlayContext!,
        message: 'Something went wrong. Please try again.',
        type: AppToastType.error,
      );
    } finally {
      isSendRequestLoading.value = false;
    }
  }

  Future<void> sendPaymentInfo() async {
    paymentInfoSending.value = true;

    final SharedPreferences pref = await SharedPreferences.getInstance();
    final RequestDietService service = RequestDietService();

    dio.MultipartFile? proofMultipart;

    // fromBytes, not fromFile(path) - path is only a blob: URL on Flutter
    // Web (see pickedPaymentImageBytes' doc comment), so fromFile silently
    // failed there and every web payment-proof submission never actually
    // attached the image.
    if (pickedPaymentImage.value != null &&
        pickedPaymentImageBytes.value != null) {
      proofMultipart = dio.MultipartFile.fromBytes(
        pickedPaymentImageBytes.value!,
        filename: pickedPaymentImage.value!.name,
      );
    }

    // Use the stored requestId, or fall back to the reactive one
    String? storedRequestId = pref.getString('requestId');
    if (storedRequestId == null || storedRequestId.isEmpty) {
      storedRequestId = requestId.value;
    }

    if (storedRequestId.isEmpty) {
      showAppToast(
        Get.overlayContext!,
        message: 'No request ID found. Please refresh and try again.',
        type: AppToastType.error,
      );
      paymentInfoSending.value = false;
      return;
    }

    final remaining = remainingAmount.value;
    final data = <String, dynamic>{
      'requestId': storedRequestId,
      'amountReceived': paidAmountController.text.trim(),
      'amountPending': remaining % 1 == 0
          ? remaining.toInt().toString()
          : remaining.toStringAsFixed(2),
    };

    // Attach coupon info if applied
    if (appliedCouponCode.value.isNotEmpty) {
      data['couponCode'] = appliedCouponCode.value;
      data['discountPercentage'] = appliedDiscount.value.toString();
      data['originalAmount'] = selectedPlanAmount.value.toInt().toString();
    }

    // Only meaningful (and only shown in the UI) when a balance is left
    if (remaining > 0 && pendingPaymentDateController.text.trim().isNotEmpty) {
      final parts = pendingPaymentDateController.text.trim().split('/');
      data['pendingPaymentDate'] = parts.length == 3
          ? '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}'
          : pendingPaymentDateController.text.trim();
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
        showAppToast(
          Get.overlayContext!,
          message:
              'Payment details sent successfully. Please wait for dietician review.',
          type: AppToastType.success,
        );
        await Posthog().capture(
          eventName: 'payment_submitted',
          properties: {
            'plan_name': selectedPlanName.value,
            'amount_paid': double.tryParse(paidAmountController.text.trim()) ?? 0,
            'coupon_applied': appliedCouponCode.value.isNotEmpty,
          },
        );

        // Send payment notification in chat
        try {
          final paidAmt = paidAmountController.text.trim();
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
        pickedPaymentImageBytes.value = null;
        pendingPaymentDateController.clear();
        removeCoupon(); // also re-defaults paidAmountController via _recalculateAmounts
        _evaluateCanSubmitPayment();
      } else {
        showAppToast(
          Get.overlayContext!,
          message: 'Failed to send payment details. Please try again.',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      debugPrint('------------> $e');
      showAppToast(
        Get.overlayContext!,
        message: 'Something went wrong. Please try again.',
        type: AppToastType.error,
      );
    } finally {
      paymentInfoSending.value = false;
    }
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
      await Posthog().capture(
        eventName: 'coupon_applied',
        properties: {
          'discount_percentage': appliedDiscount.value,
          'plan_name': selectedPlanName.value,
        },
      );
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

  /// Recomputes discountValue/finalAmount from selectedPlanAmount +
  /// appliedDiscount only - safe to call from a background poll
  /// (fetchRequestStatus) since it never touches paidAmountController,
  /// unlike _recalculateAmounts below which would otherwise stomp whatever
  /// the patient is mid-typing into Paid Amount every 30 seconds.
  void _recalculateFinalAmount() {
    if (appliedDiscount.value > 0) {
      discountValue.value =
          (selectedPlanAmount.value * appliedDiscount.value) / 100;
      finalAmount.value = selectedPlanAmount.value - discountValue.value;
    } else {
      discountValue.value = 0;
      finalAmount.value = selectedPlanAmount.value;
    }
  }

  /// Same as above, plus re-defaults Paid Amount to "paid in full" against
  /// the new total - only safe to call from a deliberate, in-screen user
  /// action (coupon apply/remove, picking a plan) since it overwrites
  /// paidAmountController.
  void _recalculateAmounts() {
    _recalculateFinalAmount();
    paidAmountController.text = finalAmount.value.toInt().toString();
    recalculateRemainingAmount(finalAmount.value);
  }

  /// Called both after `_recalculateAmounts` above and live as the patient
  /// edits paidAmountController (see payment_status_sheet.dart's onChange) -
  /// owedAmount is the subscription total after discount in the
  /// fresh-payment flow, or the previously-recorded pending balance in the
  /// pay-off-pending flow (PaymentStatusSheet.isPendingPayment), since those
  /// are two different "amount owed" baselines sharing this same
  /// paid/remaining UI.
  void recalculateRemainingAmount(double owedAmount) {
    final paid = double.tryParse(paidAmountController.text.trim()) ?? 0;
    final remaining = owedAmount - paid;
    remainingAmount.value = remaining > 0 ? remaining : 0;
    _evaluateCanSubmitPayment();
  }

  /// One-time setup for the payment-proof form - called from
  /// PaymentStatusSheet's initState (not build, which DraggableScrollableSheet
  /// can re-invoke on every drag frame and would otherwise stomp whatever the
  /// patient already typed). Defaults Paid Amount to "paid in full" against
  /// whichever baseline this mode owes.
  void initPaymentForm({required bool isPendingPayment}) {
    final owed = isPendingPayment
        ? latestAmountPending.value
        : finalAmount.value;
    paidAmountController.text = owed % 1 == 0
        ? owed.toInt().toString()
        : owed.toStringAsFixed(2);
    pendingPaymentDateController.clear();
    recalculateRemainingAmount(owed);
  }
}
