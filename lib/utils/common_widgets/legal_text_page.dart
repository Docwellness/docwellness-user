import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Single source of truth for Terms of Service / Privacy Policy content, so
// every entry point (Settings, the signup screen's consent text, etc.) shows
// the exact same text via the exact same page.

const String privacyPolicyText = '''
Privacy Policy

Last updated: March 2026

DocWellness ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information.

Information We Collect:
• Personal information (name, email, phone number)
• Health data (weight, height, BMI, dietary preferences)
• Meal logs and diet plan progress
• Device information for app functionality

How We Use Your Information:
• To provide personalized diet plans and health tracking
• To connect you with your assigned dietician
• To send notifications about your diet plan and progress
• To improve our services

Data Security:
We implement appropriate security measures to protect your personal information. Your health data is stored securely and is only accessible to you and your assigned dietician.

Your Rights:
• Access your personal data
• Request correction of your data
• Delete your account and all associated data
• Opt out of notifications

Contact Us:
For any privacy concerns, please contact us through the app's chat feature or email support.
''';

const String termsOfServiceText = '''
Terms of Service

Last updated: March 2026

Welcome to DocWellness. By using our app, you agree to these Terms of Service.

1. Acceptance of Terms
By accessing or using DocWellness, you agree to be bound by these terms. If you do not agree, please do not use the app.

2. Description of Service
DocWellness provides diet planning, meal tracking, and wellness monitoring services. Our dieticians create personalized diet plans based on your health profile.

3. User Responsibilities
• Provide accurate health information
• Follow diet plans as recommended by your dietician
• Keep your account credentials secure
• Use the app for personal, non-commercial purposes only

4. Health Disclaimer
DocWellness is not a substitute for professional medical advice. Always consult with your healthcare provider before making significant dietary changes. Our dieticians provide dietary guidance, not medical treatment.

5. Payment
Diet plan services may require payment. Payment terms will be communicated through the app. All payments are subject to our refund policy.

6. Account Termination
You may delete your account at any time. We reserve the right to suspend or terminate accounts that violate these terms.

7. Limitation of Liability
DocWellness is provided "as is". We are not liable for any health outcomes resulting from following or not following diet plans provided through the app.

8. Changes to Terms
We may update these terms from time to time. Continued use of the app constitutes acceptance of updated terms.
''';

/// Navigates to a simple scrollable text page - used for both Terms of
/// Service and Privacy Policy (and reusable for any other static legal copy).
void showLegalTextPage(String title, String content) {
  Get.to(
    () => Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: title,
          fontWeight: FontWeight.w400,
          fontSize: 19,
          color: const Color(0xff851653),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: GoogleFonts.roboto(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xff4D5761),
          ),
        ),
      ),
    ),
  );
}
