import 'package:docwellness/app/modules/home/widgets/diet_info_actions.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoDietWidget extends StatelessWidget {
  /// When embedded inside DietAndExerciseScreen the parent already owns the
  /// single Scaffold / AppBar / "Diet Plan" header and the single bottom
  /// action slot (see DietInfoActions), so this widget contributes only its
  /// illustration + message body. Standalone (the request-diet-plan flow's
  /// Get.off(() => const NoDietWidget()) and the deep-link route) it renders
  /// the whole screen itself.
  final bool embedded;

  const NoDietWidget({super.key, this.embedded = false});

  Widget _body() {
    // SingleChildScrollView (not a fixed-height Column) so the
    // illustration/text never overflows on a short screen - the action
    // buttons live in the bottom slot below instead, pinned above the
    // system nav bar rather than scrolling with this content.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 43),
          Image.asset(
            'assets/icons/60d178b5113c2afe80c762a7ff3554a8f1a3f8c3.gif',
          ),
          const SizedBox(height: 40),
          const CustomText(
            text: "No diet assigned",
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xff851653),
          ),
          const SizedBox(height: 13),
          const CustomText(
            text:
                "I am currently working on your Diet & Nutrition plan. Stay connected for more details.",
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xff4D5761),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (embedded) return _body();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Text(
          "Diet Plan",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            color: const Color(0xff1F2A37),
          ),
        ),
      ),
      body: _body(),
      // Pinned above the system/app bottom nav bar (SafeArea reserves that
      // inset) instead of living inside the scrollable body, so it's always
      // reachable without scrolling and never sits flush against the nav bar.
      bottomNavigationBar: const DietInfoActions(),
    );
  }
}
