import 'package:docwellness/app/modules/auth/services/auth_service.dart';
import 'package:docwellness/app/modules/auth/views/reset_password_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:docwellness/utils/functions/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final RxBool isLoading = false.obs;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    isLoading.value = true;
    final email = emailController.text.trim();
    await AuthService().forgotPassword(email);
    isLoading.value = false;
    Get.to(() => ResetPasswordView(email: email));
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
          text: 'Forgot password',
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
              const CustomText(
                text: 'Enter your email and we\'ll send you a code to reset your password',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xff4D5761),
              ),
              const SizedBox(height: 32),

              CustomField(
                space: false,
                lable: 'Email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),

              const SizedBox(height: 32),

              Obx(
                () => CustomButton(
                  isLoading: isLoading.value,
                  onTap: _submit,
                  text: 'Send Reset Code',
                  isOutline: false,
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const CustomText(
                    text: 'Back to Login',
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
