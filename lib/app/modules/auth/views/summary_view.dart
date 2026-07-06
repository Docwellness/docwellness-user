import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/sign_up_view.dart';
import 'package:docwellness/app/modules/auth/widgets/bmi_container.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SummaryView extends StatelessWidget {
  final List<String> healthConcerentList;
  SummaryView({super.key, required this.healthConcerentList});
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'Summary',
          fontWeight: FontWeight.w400,
          fontSize: 20,
          color: Color(0xff851653),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(height: 16),
            CustomText(
              text: 'Personal summary based on your answers',
              fontWeight: FontWeight.w500,
              fontSize: 19,
              color: Color(0xff851653),
              textAlign: TextAlign.center,
              height: 1.2,
            ),
            SizedBox(height: 25),
            Obx(
              () => BmiContainer(
                index: controller.bmiIndex.value,
                value: controller.bmi.value,
                targetedWeight: controller.selectedTargetWeight.value,
                activityLevel: controller.activityLevel.value,
                healthConcerentList: healthConcerentList,
              ),
            ),
            SizedBox(height: 56),
            CustomButton(
              onTap: () {
                Get.to(() => SignUpView(healthConcerns: healthConcerentList,));
              },
              text: 'Next',
              isOutline: false,
            ),
            SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
