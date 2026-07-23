import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/widgets/contact_sheet.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class NoDietWidget extends StatelessWidget {
  const NoDietWidget({super.key});

  // Switches the bottom nav's active tab back to Home (index 0) - same
  // mechanism BottomNaviBar's own tab taps use. That alone is enough when
  // this widget is shown inline as the Diet tab's body (BottomNaviBar is
  // already the frontmost route, so its Obx just rebuilds in place) - but
  // the request-diet-plan flow reaches this same widget via a *pushed*
  // route on top of BottomNaviBar (see request_diet_plan.view.dart's
  // Get.off(() => const NoDietWidget())), where flipping selectedIndex has
  // no visible effect since BottomNaviBar is buried underneath and isn't
  // even rebuilding. Get.until() pops back to the /home route explicitly -
  // a no-op when it's already frontmost (the Diet-tab case), so this is
  // safe to always call.
  Future<void> _goHome() async {
    if (Get.isRegistered<HomeController>()) {
      final controller = Get.find<HomeController>();
      controller.onTabSelected(0);
      controller.changeTab(0);
    }
    Get.until((route) => route.settings.name == Routes.HOME);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Text(
          "Diet Plan",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            color: Color(0xff1F2A37),
          ),
        ),
      ),
      // SingleChildScrollView (not a fixed-height Column) so the
      // illustration/text never overflows on a short screen - the action
      // buttons live in bottomNavigationBar below instead, pinned above the
      // system nav bar rather than scrolling with this content.
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 43),
            Image.asset(
              'assets/icons/60d178b5113c2afe80c762a7ff3554a8f1a3f8c3.gif',
            ),
            SizedBox(height: 40),
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
            SizedBox(height: 32),
          ],
        ),
      ),
      // Pinned above the system/app bottom nav bar (SafeArea reserves that
      // inset) instead of living inside the scrollable body, so it's always
      // reachable without scrolling and never sits flush against the nav bar.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomButton(
                fontSize: 14,
                buttonColor: Color(0xff851653),
                onTap: () => showContactSheet(context),
                text: 'Contact us',
                isOutline: false,
              ),
              SizedBox(height: 16),
              CustomButton(
                fontSize: 14,
                buttonColor: Color(0xff851653),
                onTap: () async {
                  await _goHome();
                },
                text: 'Back to Main Screen',
                isOutline: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
