import 'package:docwellness/app/modules/auth/services/auth_service.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Second half of the "forgot password" flow: the user enters the code
/// emailed by AuthService.forgotPassword() plus a new password. Verifying
/// the code establishes a Supabase session directly (no backend call
/// needed), which is then used to actually change the password.
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      final verifyRes = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: codeController.text.trim(),
        type: OtpType.recovery,
      );
      if (verifyRes.session == null) {
        _showError('Invalid or expired code. Please try again.');
        isLoading.value = false;
        return;
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: passwordController.text.trim()),
      );

      Get.snackbar('Success', 'Password reset. Please sign in with your new password.');
      await Supabase.instance.client.auth.signOut();
      Get.offAllNamed(Routes.AUTH);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    }
    isLoading.value = false;
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

  Future<void> _resend() async {
    await AuthService().forgotPassword(widget.email);
    Get.snackbar('Sent', 'A new code has been emailed to you');
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
      body: Padding(
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
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
