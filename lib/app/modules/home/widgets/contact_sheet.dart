import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// WhatsApp's official click-to-chat scheme (wa.me/<countrycode+number>,
// digits only) - this is the standard way to link to a WhatsApp chat without
// printing the number anywhere as visible text; the UI below only ever
// shows the label "WhatsApp", never the digits.
const String _whatsAppLink = 'https://wa.me/4915737226286';
const String _instagramLink = 'https://www.instagram.com/docwellness.fit/';

/// Shared "Get in touch" bottom sheet (Instagram/WhatsApp) used by every
/// diet-tab empty/waiting state (NoDietWidget, DietStartsSoonWidget) so a
/// patient can always reach the dietician even while there's no meal
/// content to show yet.
void showContactSheet(BuildContext context) {
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
