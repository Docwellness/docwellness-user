import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/verify_signup_code_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:docwellness/utils/functions/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();

  // First screen of the signup flow now, so AuthController may not exist
  // yet - but LoginScreen also Get.puts one, so guard against clobbering
  // it (and losing whatever it already holds) if it's already registered.
  // permanent: true so it can't be disposed by route churn later (e.g.
  // AuthController.login()'s Get.offAll).
  final AuthController controller = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
    rePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 16,
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

              /// Email
              CustomField(
                space: false,
                keyboardType: TextInputType.emailAddress,
                lable: 'Email Address',
                controller: controller.emailController,
                validator: validateEmail,
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
                  isLoading: controller.isSignUpLoading.value,
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      final sent = await controller.requestSignup(
                        password: rePasswordController.text.trim(),
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
