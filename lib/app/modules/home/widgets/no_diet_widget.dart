import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// WhatsApp's official click-to-chat scheme (wa.me/<countrycode+number>,
// digits only) - this is the standard way to link to a WhatsApp chat without
// printing the number anywhere as visible text; the UI below only ever
// shows the label "WhatsApp", never the digits.
const String _whatsAppLink = 'https://wa.me/4915737226286';
const String _instagramLink = 'https://www.instagram.com/docwellness.fit/';

class NoDietWidget extends StatelessWidget {
  const NoDietWidget({super.key});

  // Just switches the bottom nav's active tab back to Home (index 0) - same
  // mechanism BottomNaviBar's own tab taps use - rather than clearing the
  // navigation stack and rebuilding it via Get.offAllNamed, which is both
  // heavier than needed and (since HomeController/selectedIndex are
  // permanent) didn't actually land on the Home tab anyway.
  Future<void> _goHome() async {
    if (Get.isRegistered<HomeController>()) {
      final controller = Get.find<HomeController>();
      controller.onTabSelected(0);
      controller.changeTab(0);
    }
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // isDismissible defaults to true - tapping the scrim outside the
      // sheet already collapses it.
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              CustomText(
                text: 'Get in touch',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xff1F2A37),
              ),
              const SizedBox(height: 16),
              _ContactLinkTile(
                icon: FontAwesomeIcons.instagram,
                label: 'Instagram',
                onTap: () {
                  Navigator.of(ctx).pop();
                  launchUrl(
                    Uri.parse(_instagramLink),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              const SizedBox(height: 10),
              _ContactLinkTile(
                icon: FontAwesomeIcons.whatsapp,
                label: 'WhatsApp',
                onTap: () {
                  Navigator.of(ctx).pop();
                  launchUrl(
                    Uri.parse(_whatsAppLink),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
                onTap: () => _showContactSheet(context),
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

class _ContactLinkTile extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 12,
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffFCE7F6)),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xffFDF2FA),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, color: const Color(0xff851653), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                text: label,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xff1F2A37),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xff9DA4AE),
            ),
          ],
        ),
      ),
    );
  }
}
