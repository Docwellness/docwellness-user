import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileController extends GetxController {
  final RequestDietService service = RequestDietService();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final emailController = TextEditingController();
  final numberController = TextEditingController();

  RxString selectedGender = ''.obs;
  RxString selectedPG = ''.obs;
  RxDouble bmi = 0.0.obs;
  RxInt bmiIndex = 0.obs;
  RxBool isLoading = true.obs;
  RxBool isSaving = false.obs;
  RxBool canEdit = true.obs;

  void setGender(String value) => selectedGender.value = value;
  void setPG(String value) => selectedPG.value = value;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  @override
  void onClose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    emailController.dispose();
    numberController.dispose();
    super.onClose();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    await Future.wait([_loadUserData(), _checkDietRequestStatus()]);
    isLoading.value = false;
  }

  Future<void> _loadUserData() async {
    if (token == null || token!.isEmpty) return;

    try {
      final response = await service.getUserInfo();
      if (response == null) return;

      final profile = response['data']?['profile'] ?? {};
      final healthProfile = response['data']?['healthProfile'] ?? {};
      final userEmail = response['data']?['email'];

      if (profile['fullName'] != null) {
        nameController.text = profile['fullName'].toString();
      }

      if (profile['gender'] != null) {
        selectedGender.value = profile['gender'].toString();
      }

      final rawDate = profile['dateOfBirth'];
      if (rawDate != null && rawDate.toString().isNotEmpty) {
        final date = DateTime.parse(rawDate);
        ageController.text =
            "${date.day.toString().padLeft(2, '0')}/"
            "${date.month.toString().padLeft(2, '0')}/"
            "${date.year}";
      }

      if (profile['whatsappNumber'] != null) {
        numberController.text = profile['whatsappNumber'].toString();
      }

      if (userEmail != null) {
        emailController.text = userEmail.toString();
      }

      if (healthProfile['weight'] != null) {
        weightController.text = healthProfile['weight'].toString();
      }

      if (healthProfile['height'] != null) {
        heightController.text = healthProfile['height'].toString();
      }

      if (healthProfile['primaryGoal'] != null) {
        selectedPG.value = healthProfile['primaryGoal'].toString();
      }

      if (healthProfile['bmi'] != null) {
        bmi.value = (healthProfile['bmi'] as num).toDouble();
        _updateBmiIndex();
      } else {
        updateBMI();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _checkDietRequestStatus() async {
    try {
      final response = await service.getRequestStatus();
      if (response != null && response['data'] != null) {
        final hasRequest = response['data']['hasRequest'] == true;
        canEdit.value = !hasRequest;
      }
    } catch (e) {
      debugPrint('Error checking diet request status: $e');
    }
  }

  double calculateBMI() {
    final weight = double.tryParse(weightController.text) ?? 0;
    final heightCm = double.tryParse(heightController.text) ?? 0;
    if (weight <= 0 || heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return double.parse((weight / (heightM * heightM)).toStringAsFixed(1));
  }

  void _updateBmiIndex() {
    if (bmi.value <= 0) {
      bmiIndex.value = 0;
    } else if (bmi.value < 18.5) {
      bmiIndex.value = 1;
    } else if (bmi.value < 25) {
      bmiIndex.value = 0;
    } else if (bmi.value < 30) {
      bmiIndex.value = 2;
    } else {
      bmiIndex.value = 3;
    }
  }

  void updateBMI() {
    bmi.value = calculateBMI();
    _updateBmiIndex();
  }

  Future<void> saveProfile() async {
    if (!canEdit.value) return;

    isSaving.value = true;

    String formatDob(String input) {
      final parts = input.split('/');
      return "${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}";
    }

    final cleanPhone = numberController.text.trim().replaceAll(' ', '');

    try {
      // Update profile
      final profileBody = {
        'profile': {
          'fullName': nameController.text.trim(),
          'gender': selectedGender.value,
          'dateOfBirth': formatDob(ageController.text.trim()),
          'whatsappNumber': cleanPhone,
        },
        'email': emailController.text.trim(),
      };

      final profileResult = await service.updateProfile(profileBody);

      // Update health profile
      final healthBody = {
        'weight': weightController.text.trim(),
        'height': heightController.text.trim(),
        'bmi': bmi.value,
        'weightIndex': bmiIndex.value,
        'primaryGoal': selectedPG.value,
      };

      final healthResult = await service.updateHealthProfile(healthBody);

      if (profileResult != null || healthResult != null) {
        Get.snackbar('Success', 'Profile updated successfully',
            backgroundColor: Colors.green.shade50,
            colorText: Colors.green.shade900,
            snackPosition: SnackPosition.TOP);
        Get.back();
      } else {
        Get.snackbar('Error', 'Failed to update profile',
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade900,
            snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      Get.snackbar('Error', 'Something went wrong. Please try again.',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.TOP);
    }

    isSaving.value = false;
  }
}
