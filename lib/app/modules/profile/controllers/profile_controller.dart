import 'package:docwellness/app/modules/home/controllers/water_controller.dart';
import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final RequestDietService service = RequestDietService();
  final ImagePicker _imagePicker = ImagePicker();

  RxBool isLoading = true.obs;
  RxBool isUploading = false.obs;
  RxString fullName = ''.obs;
  RxString email = ''.obs;
  RxString profileImage = ''.obs;
  RxDouble bmi = 0.0.obs;
  RxDouble bmr = 0.0.obs;
  RxDouble tdee = 0.0.obs;
  RxDouble weight = 0.0.obs;
  RxDouble height = 0.0.obs;
  RxString primaryGoal = ''.obs;
  RxString targetWeight = ''.obs;
  RxList<double> weightTrendValues = <double>[].obs;
  RxList<String> weightTrendDates = <String>[].obs;
  RxDouble weightChangePercent = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    isLoading.value = true;

    final response = await service.getUserInfo();

    if (response != null && response['data'] != null) {
      final user = response['data'];
      final profile = user['profile'] ?? {};
      final health = user['healthProfile'] ?? {};

      fullName.value = profile['fullName'] ?? 'User';
      email.value = user['email'] ?? '';
      profileImage.value = profile['profileImage'] ?? '';
      primaryGoal.value = health['primaryGoal'] ?? '';

      double w = (health['weight'] ?? 0).toDouble();
      double h = (health['height'] ?? 0).toDouble();
      weight.value = w;
      height.value = h;
      targetWeight.value = (health['targetWeight'] ?? '').toString();

      if (h > 0 && w > 0) {
        double hm = h / 100;
        bmi.value = double.parse((w / (hm * hm)).toStringAsFixed(1));

        // Calculate age from date of birth
        int age = 25; // default fallback
        final dobStr = profile['dateOfBirth'];
        if (dobStr != null && dobStr.toString().isNotEmpty) {
          try {
            final dob = DateTime.parse(dobStr.toString());
            final now = DateTime.now();
            age = now.year - dob.year;
            if (now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day)) {
              age--;
            }
            if (age < 1) age = 25;
          } catch (_) {}
        }

        // Mifflin-St Jeor equation (gender-specific)
        final gender = (profile['gender'] ?? 'Male').toString().toLowerCase();
        if (gender == 'female') {
          bmr.value = 10 * w + 6.25 * h - 5 * age - 161;
        } else {
          bmr.value = 10 * w + 6.25 * h - 5 * age + 5;
        }

        // TDEE based on actual activity level
        final actLevel = (health['activityLevel'] ?? '').toString();
        double actMultiplier;
        switch (actLevel) {
          case 'Sedentary':
            actMultiplier = 1.2;
            break;
          case 'Lightly Activity':
            actMultiplier = 1.375;
            break;
          case 'Very Active':
            actMultiplier = 1.725;
            break;
          default:
            actMultiplier = 1.55; // Moderately Active
        }
        tdee.value = bmr.value * actMultiplier;
      }
    }

    isLoading.value = false;

    // Fetch weight trend data in background
    _fetchProgressStats();
  }

  Future<void> pickAndUploadImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;

    isUploading.value = true;
    try {
      final imageUrl = await service.uploadProfileImage(image.path);
      if (imageUrl != null) {
        profileImage.value = imageUrl;
        showAppToast(
          Get.overlayContext!,
          message: 'Profile photo updated',
          type: AppToastType.success,
        );
      } else {
        showAppToast(
          Get.overlayContext!,
          message: 'Failed to upload photo',
          type: AppToastType.error,
        );
      }
    } catch (_) {
      showAppToast(
        Get.overlayContext!,
        message: 'Failed to upload photo',
        type: AppToastType.error,
      );
    }
    isUploading.value = false;
  }

  Future<void> _fetchProgressStats() async {
    try {
      final apiService = ApiService();
      final response = await apiService.request(
        endPoint: '/progress/stats?period=month',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final data = response.data['data'];
        final trend = data['weightTrend'] as List? ?? [];

        if (trend.isNotEmpty) {
          weightTrendValues.value = trend
              .map<double>((e) => (e['weight'] ?? 0).toDouble())
              .toList();

          weightTrendDates.value = trend.map<String>((e) {
            try {
              final date = DateTime.parse(e['date'].toString());
              final months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];
              return '${date.day} ${months[date.month - 1]}';
            } catch (_) {
              return '';
            }
          }).toList();

          // Calculate percentage change
          final startW = data['startWeight'];
          final changeW = data['weightChange'];
          if (startW != null && startW > 0 && changeW != null) {
            weightChangePercent.value = double.parse(
              ((changeW / startW) * 100).toStringAsFixed(1),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      // Sync + clear water data before wiping SharedPreferences so no
      // unsynced entries are lost and the next user starts with a blank state
      try {
        final waterController = Get.find<WaterController>();
        await waterController.syncAndClear();
      } catch (_) {}

      // Sign out of Supabase - this is what actually invalidates the
      // session; the backend logout call below is just a best-effort
      // legacy no-op kept for backward compatibility.
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}

      try {
        final apiService = ApiService();
        await apiService.request(
          endPoint: '/auth/logout',
          method: 'POST',
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {}

      // Disconnect socket before clearing data
      try {
        final socketService = Get.find<SocketService>();
        socketService.disconnect();
      } catch (_) {}

      final pref = await SharedPreferences.getInstance();
      await pref.clear();

      // Clear in-memory globals so services stop using stale credentials
      token = null;
      userId = null;
      role = null;

      await Posthog().capture(eventName: 'user_logged_out');
      await Posthog().reset();

      Get.offAllNamed(Routes.AUTH);
    } catch (_) {
      Get.offAllNamed(Routes.AUTH);
    }
  }
}
