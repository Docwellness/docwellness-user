import 'package:docwellness/app/modules/auth/services/auth_service.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  /// Lands on Home (index 0) and forces an immediate fresh data fetch - see
  /// HomeController.resetForFreshLogin's doc comment for why this can't just
  /// rely on HomeController's own onInit (it's a permanent singleton, so
  /// onInit only ever fires once per app session, not on every login).
  void _landOnFreshHome() {
    Get.offAllNamed(Routes.HOME);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().resetForFreshLogin();
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade900,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

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
  RxBool isVerifyingOtp = false.obs;

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

  // ── SIGN UP (two steps: request a code, then verify + link profile) ──

  String _pendingUsername = '';
  String _pendingPassword = '';
  List<String> _pendingHealthConcerns = [];

  String _formatDob(String input) {
    final parts = input.split('/');
    return "${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}";
  }

  /// Step 1: creates the Supabase identity (unconfirmed) and emails a
  /// verification code. Returns true on success - the caller should then
  /// navigate to the OTP-entry screen.
  Future<bool> requestSignup({
    required String userName,
    required String password,
    required List<String> healthConcerns,
  }) async {
    isSignUpLoading.value = true;
    _pendingUsername = userName;
    _pendingPassword = password;
    _pendingHealthConcerns = healthConcerns;
    bool success = false;

    try {
      final response = await _authService.signupRequest(
        email: emailController.text.trim(),
        password: password,
        username: userName,
      );

      if (response['success'] == true) {
        success = true;
      } else {
        _showError(response['message'] ?? 'Signup failed. Please try again.');
      }
    } catch (e) {
      debugPrint('--------------- requestSignup error: $e');
      _showError('Something went wrong. Please try again.');
    }

    isSignUpLoading.value = false;
    return success;
  }

  /// Step 2: verifies the emailed code (establishing a Supabase session),
  /// then links that identity to a new Mongo profile using all the data
  /// collected across the onboarding screens.
  Future<bool> verifySignupCode(String code) async {
    isVerifyingOtp.value = true;
    bool success = false;

    try {
      final verifyRes = await Supabase.instance.client.auth.verifyOTP(
        email: emailController.text.trim(),
        token: code,
        type: OtpType.signup,
      );
      final session = verifyRes.session;
      if (session == null) {
        _showError('Invalid or expired code. Please try again.');
        isVerifyingOtp.value = false;
        return false;
      }
      token = session.accessToken;

      final cleanPhone = numberController.text.trim().replaceAll(' ', '');
      final body = {
        "username": _pendingUsername,
        "profile": {
          "fullName": nameController.text.trim(),
          "gender": selectedGender.value,
          "dateOfBirth": _formatDob(ageController.text.trim()),
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
          "healthConcerns": _pendingHealthConcerns,
          "bmi": bmi.value,
          "weightIndex": bmiIndex.value,
        },
      };

      final response = await _authService.register(body);

      if (response['success'] == true) {
        final data = response['data']['data'];
        userId = data['_id'];
        role = data['role'];

        final pref = await SharedPreferences.getInstance();
        pref.setString('userId', userId!);
        pref.setString('token', token!);
        pref.setString('role', role!);

        await Posthog().identify(
          userId: userId!,
          userProperties: {
            'primary_goal': selectedPG.value,
            'gender': selectedGender.value,
          },
        );
        await Posthog().capture(
          eventName: 'user_signed_up',
          properties: {
            'primary_goal': selectedPG.value,
            'activity_level': activityLevel.value,
            'health_concerns_count': _pendingHealthConcerns.length,
          },
        );

        Get.snackbar("Success", response['data']['message'] ?? 'Welcome to DocWellness!');
        _landOnFreshHome();
        success = true;
      } else {
        _showError(response['message'] ?? 'Registration failed. Please try again.');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      debugPrint('--------------- verifySignupCode error: $e');
      _showError('Something went wrong. Please try again.');
    }

    isVerifyingOtp.value = false;
    return success;
  }

  /// Re-sends the signup verification code (just calls the same request
  /// again - the backend always issues a fresh code).
  Future<bool> resendSignupCode() {
    return requestSignup(
      userName: _pendingUsername,
      password: _pendingPassword,
      healthConcerns: _pendingHealthConcerns,
    );
  }

  // ── LOGIN ──

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

    try {
      final input = loginUserNameController.text.trim();
      final password = loginPasswordController.text.trim();
      final isEmail = input.contains('@');

      final email = isEmail ? input : await _authService.resolveUsernameToEmail(input);
      if (email == null) {
        loginError.value = 'Invalid username or password';
        isLoginLoading.value = false;
        return;
      }

      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = authRes.session;
      if (session == null) {
        loginError.value = 'Invalid username or password';
        isLoginLoading.value = false;
        return;
      }
      token = session.accessToken;

      final profileResponse = await _authService.getUserInfo(token!);
      if (profileResponse == null || profileResponse['data'] == null) {
        loginError.value = 'Account setup is incomplete. Please contact support.';
        isLoginLoading.value = false;
        return;
      }
      final data = profileResponse['data'];
      userId = data['_id'];
      role = data['role'];

      final pref = await SharedPreferences.getInstance();
      pref.setString('userId', userId!);
      pref.setString('token', token!);
      pref.setString('role', role!);

      await Posthog().identify(userId: userId!);
      await Posthog().capture(
        eventName: 'user_logged_in',
        properties: {'login_method': isEmail ? 'email' : 'username'},
      );

      _landOnFreshHome();
    } on AuthException catch (e) {
      loginError.value = e.message;
    } catch (e) {
      debugPrint('------------$e');
      loginError.value = 'Something went wrong. Please try again.';
    }
    isLoginLoading.value = false;
  }
}
