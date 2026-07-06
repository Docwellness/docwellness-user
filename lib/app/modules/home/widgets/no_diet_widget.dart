import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class NoDietWidget extends StatelessWidget {
  const NoDietWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        leading: IconButton(
          onPressed: () async {
            if (Get.isRegistered<HomeController>()) {
              await Get.find<HomeController>().refreshAllData();
            }
            Get.offAllNamed(Routes.HOME);
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        titleSpacing: 0,
        title: Text(
          "Diet Plan",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            color: Color(0xff1F2A37),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 43),
            Image.asset(
              'assets/icons/60d178b5113c2afe80c762a7ff3554a8f1a3f8c3.gif',
            ),
            Spacer(),
            CustomText(
              text: "No diet assigned",

              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xff851653),
            ),
            SizedBox(height: 13),

            CustomText(
              text:
                  "I am currently working on your Diet & Nutrition plan. Stay connected for more details.",

              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xff4D5761),

              textAlign: TextAlign.center,
            ),
            SizedBox(height: 56),
            CustomButton(
              fontSize: 14,
              buttonColor: Color(0xff851653),
              onTap: () {
                //  Get.to(() => DietPlanScreen());
              },
              text: 'Contact us',
              isOutline: false,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
