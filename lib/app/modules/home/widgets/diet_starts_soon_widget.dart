import 'dart:async';

import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/widgets/contact_sheet.dart';
import 'package:docwellness/app/modules/home/widgets/diet_countdown_text.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shown instead of the full diet-plan content when the active plan's
/// current week hasn't actually started yet (weekStartDate is in the
/// future - e.g. the dietician picked a future "Starting Date"). Distinct
/// from NoDietWidget, which means no plan exists at all yet - here a plan
/// genuinely exists and is scheduled, so there's nothing to "contact the
/// dietician about"; the live countdown is recomputed from [startDate]
/// every minute, so if the dietician later updates week 1's date and the
/// screen refetches (pull-to-refresh, reopening the tab, etc.), the
/// countdown reflects whatever startDate was fetched, not a stale value.
class DietStartsSoonWidget extends StatefulWidget {
  final DateTime startDate;

  const DietStartsSoonWidget({super.key, required this.startDate});

  @override
  State<DietStartsSoonWidget> createState() => _DietStartsSoonWidgetState();
}

class _DietStartsSoonWidgetState extends State<DietStartsSoonWidget> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    // Minute-granularity is enough for a "days and hours" display - no
    // need to tick every second for a countdown this coarse.
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _goHome() async {
    if (Get.isRegistered<HomeController>()) {
      final controller = Get.find<HomeController>();
      controller.onTabSelected(0);
      controller.changeTab(0);
    }
    Get.until((route) => route.settings.name == Routes.HOME);
  }

  String _countdownText() => dietCountdownText(widget.startDate);

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
              text: "Your diet plan starts soon",
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xff851653),
            ),
            SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffFCE7F6)),
              ),
              child: CustomText(
                text: _countdownText(),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xff851653),
              ),
            ),
            SizedBox(height: 13),
            CustomText(
              text:
                  "Your meal plan is ready and will unlock automatically when it starts.",
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xff4D5761),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
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
                onTap: () => _goHome(),
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
