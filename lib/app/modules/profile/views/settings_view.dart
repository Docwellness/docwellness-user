import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/legal_text_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: const CustomText(
          text: 'Settings',
          fontWeight: FontWeight.w400,
          fontSize: 19,
          color: Color(0xff851653),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _settingsTile(
            icon: Icons.language,
            title: 'Language',
            trailing: 'English',
            onTap: () {
              Get.snackbar(
                'Language',
                'Currently only English is supported',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          _settingsTile(
            icon: Icons.lock_outline,
            title: 'Privacy Policy',
            onTap: () => showLegalTextPage('Privacy Policy', privacyPolicyText),
          ),
          _settingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () =>
                showLegalTextPage('Terms of Service', termsOfServiceText),
          ),
          _settingsTile(
            icon: Icons.info_outline,
            title: 'About',
            trailing: 'v1.0.0',
            onTap: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('About DocWellness'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xffFDF2FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xffEAD4E8)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/icons/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your personal diet and wellness companion. Track meals, manage diet plans, and achieve your health goals.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '© 2026 DocWellness',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff851653), size: 22),
        title: Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xff111927),
          ),
        ),
        trailing: trailing != null
            ? Text(
                trailing,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: const Color(0xff6B7280),
                ),
              )
            : const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xff9DA4AE),
              ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
