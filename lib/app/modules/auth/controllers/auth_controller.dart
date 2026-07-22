import 'dart:convert';

import 'package:docwellness/app/modules/auth/services/auth_service.dart';
import 'package:docwellness/app/modules/auth/views/personal_info_view.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
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
    showAppToast(
      Get.overlayContext!,
      message: message,
      type: AppToastType.error,
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

  // ── ONBOARDING DRAFT PERSISTENCE ──
  // The in-memory AuthController survives navigation within a running app
  // session, but not an app restart. Personal Info through Summary can span
  // several screens filled in over multiple sittings, so progress is
  // snapshotted to SharedPreferences after each step and restored when
  // PersonalInfoView resumes (either normally, or via SplashView's "verified
  // but registration incomplete" resume path) - cleared only once
  // completeRegistration actually succeeds.
  static const _draftKey = 'onboarding_draft';

  Future<void> saveOnboardingDraft() async {
    final pref = await SharedPreferences.getInstance();
    final draft = {
      'fullName': nameController.text,
      'gender': selectedGender.value,
      'dob': ageController.text,
      'weight': weightController.text,
      'height': heightController.text,
      'phone': numberController.text,
      'primaryGoal': selectedPG.value,
      'targetWeight': selectedTargetWeight.value,
      'activityLevel': activityLevel.value,
      'healthConcerns': healthConcerns,
    };
    await pref.setString(_draftKey, jsonEncode(draft));
  }

  Future<void> restoreOnboardingDraft() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getString(_draftKey);
    if (raw == null) return;

    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      if ((draft['fullName'] as String?)?.isNotEmpty ?? false) {
        nameController.text = draft['fullName'];
      }
      if ((draft['gender'] as String?)?.isNotEmpty ?? false) {
        selectedGender.value = draft['gender'];
      }
      if ((draft['dob'] as String?)?.isNotEmpty ?? false) {
        ageController.text = draft['dob'];
      }
      if ((draft['weight'] as String?)?.isNotEmpty ?? false) {
        weightController.text = draft['weight'];
      }
      if ((draft['height'] as String?)?.isNotEmpty ?? false) {
        heightController.text = draft['height'];
      }
      if ((draft['phone'] as String?)?.isNotEmpty ?? false) {
        numberController.text = draft['phone'];
      }
      if ((draft['primaryGoal'] as String?)?.isNotEmpty ?? false) {
        selectedPG.value = draft['primaryGoal'];
      }
      if ((draft['targetWeight'] as String?)?.isNotEmpty ?? false) {
        selectedTargetWeight.value = draft['targetWeight'];
      }
      if (draft['activityLevel'] != null) {
        activityLevel.value = draft['activityLevel'] as int;
      }
      if (draft['healthConcerns'] != null) {
        healthConcerns.assignAll(List<String>.from(draft['healthConcerns']));
      }
      updateBMI();
    } catch (e) {
      debugPrint('restoreOnboardingDraft error: $e');
    }
  }

  Future<void> clearOnboardingDraft() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_draftKey);
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

  // ── SIGN UP (three steps: request a code, verify it, then - once the
  // rest of onboarding is filled in - link the Mongo profile) ──

  String _pendingPassword = '';
  // Rx (not a plain List) so SummaryView's BMI card updates immediately
  // after editing Health Concerns and coming back, instead of showing
  // whatever list was passed in when Summary was first built.
  final RxList<String> healthConcerns = <String>[].obs;
  RxBool isRegistering = false.obs;

  /// Health concerns are picked several screens after the email is
  /// verified, so they're stashed here instead of passed through
  /// requestSignup - see completeRegistration.
  void setHealthConcerns(List<String> concerns) {
    healthConcerns.assignAll(concerns);
  }

  String _formatDob(String input) {
    final parts = input.split('/');
    return "${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}";
  }

  /// Step 1: creates the Supabase identity (unconfirmed) and emails a
  /// verification code. Returns true on success - the caller should then
  /// navigate to the OTP-entry screen.
  Future<bool> requestSignup({required String password}) async {
    isSignUpLoading.value = true;
    _pendingPassword = password;
    bool success = false;

    try {
      final response = await _authService.signupRequest(
        email: emailController.text.trim(),
        password: password,
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

  /// Step 2: verifies the emailed code, establishing a Supabase session.
  /// The rest of onboarding (target weight/activity level/health concerns)
  /// is collected afterwards, so the Mongo profile isn't created yet - see
  /// completeRegistration.
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
      } else {
        token = session.accessToken;
        success = true;
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
    return requestSignup(password: _pendingPassword);
  }

  /// Step 3 (final): links the already-verified Supabase identity to a new
  /// Mongo profile using all the data collected across onboarding, once
  /// target weight/activity level/health concerns are known too.
  Future<bool> completeRegistration() async {
    isRegistering.value = true;
    bool success = false;

    try {
      final cleanPhone = numberController.text.trim().replaceAll(' ', '');
      final body = {
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
          "healthConcerns": healthConcerns,
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
            'health_concerns_count': healthConcerns.length,
          },
        );

        await clearOnboardingDraft();

        showAppToast(
          Get.overlayContext!,
          message: response['data']['message'] ?? 'Welcome to DocWellness!',
          type: AppToastType.success,
        );
        _landOnFreshHome();
        success = true;
      } else {
        _showError(response['message'] ?? 'Registration failed. Please try again.');
      }
    } catch (e) {
      debugPrint('--------------- completeRegistration error: $e');
      _showError('Something went wrong. Please try again.');
    }

    isRegistering.value = false;
    return success;
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
      final email = loginUserNameController.text.trim();
      final password = loginPasswordController.text.trim();

      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = authRes.session;
      if (session == null) {
        loginError.value = 'Invalid email or password';
        isLoginLoading.value = false;
        return;
      }
      token = session.accessToken;

      final profileResponse = await _authService.getUserInfo(token!);
      if (profileResponse == null || profileResponse['data'] == null) {
        // Email is verified (Supabase gave us a session) but registration
        // was never finished - same "confirmed, no profile yet" state
        // SplashView resumes into on an app restart. Send them to finish
        // onboarding instead of dead-ending on a "contact support" error.
        isLoginLoading.value = false;
        Get.offAll(() => const PersonalInfoView());
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
      await Posthog().capture(eventName: 'user_logged_in');

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
