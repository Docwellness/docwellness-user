import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Final step of signup: the user enters the code emailed after
/// AuthController.requestSignup() succeeds. Verifying it establishes a
/// Supabase session, then links the collected profile data to Mongo - see
/// AuthController.verifySignupCode.
class VerifySignupCodeView extends StatefulWidget {
  const VerifySignupCodeView({super.key});

  @override
  State<VerifySignupCodeView> createState() => _VerifySignupCodeViewState();
}

class _VerifySignupCodeViewState extends State<VerifySignupCodeView> {
  final _formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

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
          text: 'Verify your email',
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
                text: 'We sent a verification code to ${controller.emailController.text.trim()}',
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

              const SizedBox(height: 32),

              Obx(
                () => CustomButton(
                  isLoading: controller.isVerifyingOtp.value,
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      await controller.verifySignupCode(codeController.text.trim());
                    }
                  },
                  text: 'Verify & Continue',
                  isOutline: false,
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Obx(
                  () => TextButton(
                    onPressed: controller.isSignUpLoading.value
                        ? null
                        : () async {
                            final sent = await controller.resendSignupCode();
                            if (sent) {
                              Get.snackbar('Sent', 'A new code has been emailed to you');
                            }
                          },
                    child: const CustomText(
                      text: "Didn't get a code? Resend",
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xff851653),
                    ),
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
