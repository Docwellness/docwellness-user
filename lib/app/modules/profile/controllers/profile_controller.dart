import 'package:docwellness/app/modules/auth/services/auth_service.dart';
import 'package:docwellness/app/modules/home/controllers/water_controller.dart';
import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController extends GetxController {
  final RequestDietService service = RequestDietService();
  final ImagePicker _imagePicker = ImagePicker();

  RxBool isLoading = true.obs;
  RxBool isUploading = false.obs;
  RxString fullName = ''.obs;
  RxString email = ''.obs;
  RxString profileImage = ''.obs;
  RxDouble bmi = 0.0.obs;
  RxDouble weight = 0.0.obs;
  RxDouble height = 0.0.obs;
  RxString primaryGoal = ''.obs;
  RxString targetWeight = ''.obs;

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
      }
    }

    isLoading.value = false;
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

  Future<void> logout() async {
    try {
      // Sync + clear water data before wiping SharedPreferences so no
      // unsynced entries are lost and the next user starts with a blank state
      try {
        final waterController = Get.find<WaterController>();
        await waterController.syncAndClear();
      } catch (_) {}

      // Revokes the session server-side - this is what actually invalidates
      // it now (see docwellness-backend's /auth/logout).
      await AuthService().logout();

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
