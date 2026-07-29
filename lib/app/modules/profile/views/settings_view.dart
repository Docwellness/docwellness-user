import 'package:docwellness/app/services/recipe_language_service.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/legal_text_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _openRecipeLanguagePicker(BuildContext context) {
    final service = RecipeLanguageService.instance;
    Get.bottomSheet(
      // Material (not a plain Container) so the RadioListTiles below paint
      // their own background/ink splashes correctly - see _settingsTile's
      // doc comment for the same fix applied to the tiles further down
      // this screen.
      Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: CustomText(
                  text: 'Recipe Language',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xff111927),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: CustomText(
                  text: 'Recipes open in this language by default.',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color(0xff6B7280),
                ),
              ),
              const SizedBox(height: 8),
              ...RecipeLanguageService.supportedLanguages.map(
                (language) => Obx(
                  () => RadioListTile<String>(
                    value: language,
                    groupValue: service.current.value,
                    activeColor: const Color(0xff851653),
                    title: Text(
                      language,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff111927),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) service.setLanguage(value);
                      Get.back();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

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
          Obx(
            () => _settingsTile(
              icon: Icons.language,
              title: 'Recipe Language',
              trailing: RecipeLanguageService.instance.current.value,
              onTap: () => _openRecipeLanguagePicker(context),
            ),
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
                          'assets/icons/logo_mark.png',
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
    // ListTile paints its own background/ink splashes on the nearest
    // Material ancestor - wrapping it in a plain Container with a
    // background color (as this used to) hides both (Flutter's own
    // _debugCheckBackgroundIsHidden assertion fires on every render for
    // exactly this reason, and every tap's ripple was genuinely invisible
    // to the user). Wrapping in a Material instead - Flutter's own
    // documented fix - makes the tile paint on itself, so the pink
    // background AND the tap ripple both actually render.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
