import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/widgets/contact_sheet.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The "Contact us" / "Back to Main Screen" button pair shared by every
/// diet-tab waiting state (NoDietWidget, DietStartsSoonWidget). Extracted so
/// DietAndExerciseScreen can hoist it into its own single bottom slot -
/// where the "Log Meal" / "Report Allergies" bar (DietBottomActions) also
/// lives - and show exactly one of the two: the waiting-state actions while
/// there's no usable plan yet, the logging actions once real meal content is
/// on screen. Previously the embedded NoDietWidget/DietStartsSoonWidget each
/// dragged along their own Scaffold + bottom bar, so both pairs stacked up
/// on top of each other (see this screen's screenshot bug).
class DietInfoActions extends StatelessWidget {
  const DietInfoActions({super.key});

  // Switches the bottom nav's active tab back to Home (index 0) - same
  // mechanism BottomNaviBar's own tab taps use. Get.until() additionally
  // pops back to /home for the pushed-route case (request-diet-plan flow's
  // Get.off(() => const NoDietWidget())); a harmless no-op when the Diet tab
  // is already frontmost.
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              fontSize: 14,
              buttonColor: const Color(0xff851653),
              onTap: () => showContactSheet(context),
              text: 'Contact us',
              isOutline: false,
            ),
            const SizedBox(height: 16),
            CustomButton(
              fontSize: 14,
              buttonColor: const Color(0xff851653),
              onTap: () => _goHome(),
              text: 'Back to Main Screen',
              isOutline: true,
            ),
          ],
        ),
      ),
    );
  }
}
