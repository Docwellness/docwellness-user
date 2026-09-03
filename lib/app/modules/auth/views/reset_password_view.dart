import 'package:docwellness/app/modules/auth/services/auth_service.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:docwellness/utils/functions/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Second half of the "forgot password" flow: the user enters the code
/// emailed by AuthService.forgotPassword() plus a new password. Both are
/// sent to the backend's /auth/reset-password in one call, which verifies
/// the code and sets the new password server-side - no session needed
/// client-side at all.
class ResetPasswordView extends StatefulWidget {
  final String email;
  const ResetPasswordView({super.key, required this.email});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();
  final RxBool isLoading = false.obs;

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all fields correctly.');
      return;
    }
    isLoading.value = true;

    try {
      final response = await AuthService().resetPassword(
        email: widget.email,
        code: codeController.text.trim(),
        newPassword: passwordController.text.trim(),
      );
      if (response['success'] != true) {
        _showError(response['message'] ?? 'Invalid or expired code. Please try again.');
        isLoading.value = false;
        return;
      }

      showAppToast(
        Get.overlayContext!,
        message: 'Password reset. Please sign in with your new password.',
        type: AppToastType.success,
      );
      Get.offAllNamed(Routes.AUTH);
    } catch (e) {
      _showError('Something went wrong: $e');
    }
    isLoading.value = false;
  }

  void _showError(String message) {
    showAppToast(
      Get.overlayContext!,
      message: message,
      type: AppToastType.error,
    );
  }

  Future<void> _resend() async {
    await AuthService().forgotPassword(widget.email);
    showAppToast(
      Get.overlayContext!,
      message: 'A new code has been emailed to you',
      type: AppToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: const CustomText(
          text: 'Reset password',
          fontWeight: FontWeight.w400,
          fontSize: 20,
          color: Color(0xff851653),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              CustomText(
                text: 'Enter the code we sent to ${widget.email} and choose a new password',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: const Color(0xff4D5761),
              ),
              const SizedBox(height: 32),

              CustomField(
                space: false,
                lable: 'Verification code',
                controller: codeController,
                keyboardType: TextInputType.number,
                isPoint: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the code from your email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomField(
                space: false,
                hide: true,
                lable: 'New password',
                controller: passwordController,
                validator: (value) => validatePassword(value, email: widget.email),
              ),

              const SizedBox(height: 16),

              CustomField(
                space: false,
                hide: true,
                lable: 'Re-type new password',
                controller: rePasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please re-type your new password';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              Obx(
                () => CustomButton(
                  isLoading: isLoading.value,
                  onTap: _submit,
                  text: 'Reset Password',
                  isOutline: false,
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: _resend,
                  child: const CustomText(
                    text: "Didn't get a code? Resend",
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xff851653),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
