import 'package:docwellness/app/modules/home/widgets/no_diet_widget.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestDietPlanScreen extends StatefulWidget {
  const RequestDietPlanScreen({super.key});

  @override
  State<RequestDietPlanScreen> createState() => _RequestDietPlanScreenState();
}

class _RequestDietPlanScreenState extends State<RequestDietPlanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,

      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: const Color(0xffFDF2FA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
          onPressed: () async {
            if (Get.isRegistered<HomeController>()) {
              await Get.find<HomeController>().refreshAllData();
            }
            Get.offAllNamed(Routes.HOME);
          },
        ),
        titleSpacing: 0,
        title: CustomText(
          text: 'Connect for Payment',
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 36),

            const SizedBox(
              height: 96,
              width: 96,
              child: Image(
                image: AssetImage('assets/images/right.png'),
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 36),

            CustomText(
              text: "Request submitted",

              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xff851653),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: CustomText(
                text:
                    "Your request has been sent to the dietician. Please make the payment to proceed and successfully connect with your dietcian.",
                textAlign: TextAlign.center,

                fontSize: 12.5,
                color: Color(0xff4D5761),
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 35),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xffF9FAFB)),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      offset: Offset(0, 5),
                      blurRadius: 25,
                      spreadRadius: -4,
                    ),

                    BoxShadow(
                      color: Color(0x1B000000),
                      offset: Offset(0, 1.14),
                      blurRadius: 5.72,
                      spreadRadius: -2.67,
                    ),

                    BoxShadow(
                      color: Color(0x1F000000),
                      offset: Offset(0, 0.3),
                      blurRadius: 1.51,
                      spreadRadius: -1.33,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CustomText(
                          text: "Billed Monthly",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff851653),
                        ),

                        const SizedBox(height: 6),

                        Container(height: 2, color: const Color(0xff851653)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const FeatureTile(
                      icon: 'assets/icons/vector.png',
                      text: "Unlimited Access",
                    ),
                    const FeatureTile(
                      icon: 'assets/icons/paint.png',
                      text: "Enhanced Customization",
                    ),
                    const FeatureTile(
                      icon: 'assets/icons/chart_bar_2_line.png',
                      text: "Analytics Dashboard",
                    ),
                    const FeatureTile(
                      icon: 'assets/icons/refresh_2_line.png',
                      text: "Regular Updates",
                    ),
                    const FeatureTile(
                      icon: 'assets/icons/book_line.png',
                      text: "Exclusive Tutorials",
                    ),
                    const FeatureTile(
                      icon: 'assets/icons/tool.png',
                      text: "Collaborative Tools",
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: '₹2500/mo',
                              fontWeight: FontWeight.w600,
                              fontSize: 24,
                              color: Color(0xff020617),
                            ),
                          ],
                        ),
                        SizedBox(width: 39),

                        Expanded(
                          child: CustomButton(
                            buttonColor: Color(0xff851653),
                            onTap: () {
                              Get.off(() => const NoDietWidget());
                            },
                            text: 'Next',
                            isOutline: false,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),

                    const SizedBox(height: 10),

                    CustomText(
                      text:
                          'By proceeding, you agree to our terms and authorize a ₹2500 for one month charge starting September 1. ',

                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff9DA4AE),
                      height: 1.5,

                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 13),
          ],
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final String icon;
  final String text;
  final bool? changeColor;
  const FeatureTile({
    super.key,
    required this.icon,
    required this.text,
    this.changeColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: changeColor == true
                  ? Color(0xffF3F4F6)
                  : const Color(0xffFDF2FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Image.asset(
                icon,
                height: 20,
                width: 20,
                fit: BoxFit.contain,
                colorBlendMode: BlendMode.srcIn,
                color: changeColor == true
                    ? Color(0xff9DA4AE)
                    : Color(0xff851653),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomText(
              text: text,
              color: changeColor == true
                  ? Color(0xff9DA4AE)
                  : Color(0xff384250),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
