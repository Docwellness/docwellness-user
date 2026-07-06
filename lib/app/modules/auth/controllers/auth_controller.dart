import 'package:docwellness/app/modules/auth/services/auth_service.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  RxBool isLoadingUserData = false.obs;
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController loginUserNameController = TextEditingController();
  TextEditingController loginPasswordController = TextEditingController();

  RxString selectedGender = "".obs;
  RxString selectedPG = "".obs;
  RxString selectedTargetWeight = "".obs;
  RxInt activityLevel = 0.obs;
  RxDouble bmi = 0.0.obs;
  RxInt bmiIndex = 0.obs;
  RxBool isSignUpLoading = false.obs;
  RxBool isLoginLoading = false.obs;

  void setGender(String value) {
    selectedGender.value = value;
  }

  void setPG(String value) {
    selectedPG.value = value;
  }

  void setTargetWeight(String value) {
    selectedTargetWeight.value = value;
  }

  final formKey = GlobalKey<FormState>();
  double calculateBMI() {
    final weight = double.tryParse(weightController.text) ?? 0;
    final heightCm = double.tryParse(heightController.text) ?? 0;

    if (weight <= 0 || heightCm <= 0) return 0;

    final heightM = heightCm / 100;
    final bmiValue = weight / (heightM * heightM);

    return double.parse(bmiValue.toStringAsFixed(1));
  }

  // BMI Index: 0=Normal, 1=Underweight, 2=Overweight, 3=Obese (WHO standard)
  void updateBMI() {
    bmi.value = calculateBMI();

    if (bmi.value <= 0) {
      bmiIndex.value = 0;
    } else if (bmi.value < 18.5) {
      bmiIndex.value = 1; // Underweight
    } else if (bmi.value < 25) {
      bmiIndex.value = 0; // Normal
    } else if (bmi.value < 30) {
      bmiIndex.value = 2; // Overweight
    } else {
      bmiIndex.value = 3; // Obese
    }
  }

  // for sign up
  Future<void> signUp({
    required String userName,
    required String password,
    required List<String> healthConcerns,
  }) async {
    String formatDob(String input) {
      final parts = input.split('/');
      return "${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}";
    }

    final SharedPreferences pref = await SharedPreferences.getInstance();

    isSignUpLoading.value = true;

    // Strip all spaces from whatsapp number for backend validation
    final cleanPhone = numberController.text.trim().replaceAll(' ', '');

    final body = {
      "username": userName,
      "email": emailController.text.trim(),
      "password": password,
      "profile": {
        "fullName": nameController.text.trim(),
        "gender": selectedGender.value,
        "dateOfBirth": formatDob(ageController.text.trim()),
        "whatsappNumber": cleanPhone,
      },
      "healthProfile": {
        "weight": weightController.text.trim(),
        "height": heightController.text.trim(),
        "primaryGoal": selectedPG.value,
        "targetWeight": selectedTargetWeight.value,
        "activityLevel": activityLevel.value == 0
            ? 'Sedentary'
            : activityLevel.value == 1
            ? 'Lightly Activity'
            : activityLevel.value == 2
            ? 'Moderately Activity'
            : 'Very Active',
        "healthConcerns": healthConcerns,
        "bmi": bmi.value,
        "weightIndex": bmiIndex.value,
      },
    };

    debugPrint("-----> $body");

    try {
      final response = await _authService.signUp(body);

      if (response['success'] == true) {
        final data = response['data'];
        debugPrint('-----------${data['data']['_id']}');
        debugPrint('-----------${data['data']['token']}');
        debugPrint('-----------${data['data']['role']}');

        pref.setString('userId', data['data']['_id']);
        pref.setString('token', data['data']['token']);
        pref.setString('role', data['data']['role']);

        userId = data['data']['_id'];
        token = data['data']['token'];
        role = data['data']['role'];

        Get.snackbar("Success", data['message']);
        Get.offAllNamed(Routes.HOME);
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Signup Failed. Please try again.',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint('--------------- signUp error: $e');
      String errorMsg = 'Something went wrong. Please try again.';
      if (e.toString().contains('message:')) {
        errorMsg = e.toString();
      }
      Get.snackbar(
        'Error',
        errorMsg,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
    }
    isSignUpLoading.value = false;
  }

  // for login

  RxString loginError = ''.obs;

  Future<void> loadUserData() async {
    if (token == null || token!.isEmpty) return;

    isLoadingUserData.value = true;
    try {
      final response = await _authService.getUserInfo(token!);

      if (response != null) {
        final profile = response['data']?['profile'] ?? {};
        final healthProfile = response['data']?['healthProfile'] ?? {};

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

        if (healthProfile['weight'] != null) {
          weightController.text = healthProfile['weight'].toString();
        }

        if (healthProfile['height'] != null) {
          heightController.text = healthProfile['height'].toString();
        }

        if (healthProfile['bmi'] != null) {
          bmi.value = (healthProfile['bmi'] as num).toDouble();
          // Recalculate proper BMI index from value (WHO standard)
          if (bmi.value < 18.5) {
            bmiIndex.value = 1; // Underweight
          } else if (bmi.value < 25) {
            bmiIndex.value = 0; // Normal
          } else if (bmi.value < 30) {
            bmiIndex.value = 2; // Overweight
          } else {
            bmiIndex.value = 3; // Obese
          }
        }

        if (healthProfile['primaryGoal'] != null) {
          selectedPG.value = healthProfile['primaryGoal'].toString();
        }

        if (healthProfile['targetWeight'] != null) {
          selectedTargetWeight.value = healthProfile['targetWeight'].toString();
        }

        if (healthProfile['activityLevel'] != null) {
          String activity = healthProfile['activityLevel'].toString();
          if (activity == 'Sedentary') {
            activityLevel.value = 0;
          } else if (activity == 'Lightly Activity') {
            activityLevel.value = 1;
          } else if (activity == 'Moderately Activity') {
            activityLevel.value = 2;
          } else {
            activityLevel.value = 3;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    isLoadingUserData.value = false;
  }

  Future<void> login() async {
    isLoginLoading.value = true;
    loginError.value = '';
    final SharedPreferences pref = await SharedPreferences.getInstance();
    try {
      final input = loginUserNameController.text.trim();
      final isEmail = input.contains('@');
      final response = await _authService.login({
        if (isEmail) 'email': input else 'username': input,
        'password': loginPasswordController.text.trim(),
      });
      if (response != null && response['success'] == true) {
        debugPrint('-----------${response['_id']}');
        debugPrint('-----------${response['token']}');
        debugPrint('-----------${response['role']}');

        pref.setString('userId', response['_id']);
        pref.setString('token', response['token']);
        pref.setString('role', response['role']);

        userId = response['_id'];
        token = response['token'];
        role = response['role'];

        Get.offAllNamed(Routes.HOME);
      } else {
        loginError.value = 'Invalid username or password';
      }
    } catch (e) {
      debugPrint('------------$e');
      loginError.value = 'Something went wrong. Please try again.';
    }
    isLoginLoading.value = false;
  }
}
