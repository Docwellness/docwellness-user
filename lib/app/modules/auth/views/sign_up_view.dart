import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/verify_signup_code_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpView extends StatefulWidget {
  final List<String> healthConcerns;
  const SignUpView({super.key, required this.healthConcerns});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

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
          text: 'Login data',
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
            children: [
              const SizedBox(height: 40),

              /// Username
              CustomField(
                space: false,
                lable: 'Username',
                controller: usernameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter username";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Password
              CustomField(
                space: false,

                hide: true,

                lable: 'Password',
                controller: passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter password";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Re-type Password
              CustomField(
                space: false,

                hide: true,
                lable: 'Re-type Password',
                controller: rePasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please re-type password";
                  }
                  if (value != passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 48),

              /// Button
              Obx(
                () => CustomButton(
                  isLoading: Get.find<AuthController>().isSignUpLoading.value,
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      final sent = await Get.find<AuthController>().requestSignup(
                        userName: usernameController.text.trim(),
                        password: rePasswordController.text.trim(),
                        healthConcerns: widget.healthConcerns,
                      );
                      if (sent) {
                        Get.to(() => const VerifySignupCodeView());
                      }
                    }
                  },
                  text: 'Complete Sign Up',
                  isOutline: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
