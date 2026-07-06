import 'package:docwellness/app/modules/auth/views/login_view.dart';
import 'package:docwellness/app/modules/auth/views/personal_info_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFEF6FB),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 55),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage('assets/icons/logo.png'),
                    height: 38,
                    width: 38,
                  ),
                  SizedBox(width: 15),
                  CustomText(
                    text: 'DocWellness',
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Color(0xff530630),
                  ),
                ],
              ),
              SizedBox(height: 72),
              SizedBox(
                height: 209,
                child: Image.asset('assets/images/pic.png'),
              ),
              SizedBox(height: 72),
              CustomText(
                text: 'Welcome to DocWellness!',
                fontWeight: FontWeight.w500,
                fontSize: 22,
                color: Color(0xff851653),
              ),

              SizedBox(height: 13),
              CustomText(
                text:
                    ' You go to app for every health need. We’re here to help you all your health based needs anytime, anywhere. Empowering Your Wellness, Every Day.',
                fontWeight: FontWeight.w400,
                fontSize: 11.5,
                color: Color(0xff4D5761),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 72),
              SizedBox(
                width: 68,
                child: Image.asset('assets/images/indicators.png'),
              ),
              SizedBox(height: 72),
              CustomButton(
                fontSize: 14,
                onTap: () {
                  Get.to(() => LoginScreen());
                },
                text: "Log in",
                isOutline: false,
              ),
              SizedBox(height: 20),
              CustomButton(
                fontSize: 14,
                onTap: () {
                  Get.to(() => PersonalInfoView());
                },
                text: "I’m new, Sign me up",
                isOutline: true,
              ),
              SizedBox(height: 19),
              CustomText(
                text:
                    'By logging on or registering, you agree to our terms and conditions and privacy policy.',
                fontWeight: FontWeight.w400,
                fontSize: 11.5,
                color: Color(0xff6C737F),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}
