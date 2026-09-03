import 'package:docwellness/app/modules/auth/services/auth_service.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/services/first_consultation_service.dart';
import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/app/modules/home/views/view_first_consultation_view.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/functions/validators.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final RequestDietService service = RequestDietService();
  final FirstConsultationService _consultationService = FirstConsultationService();
  bool isLoading = true;
  String fullName = '';
  String email = '';
  String gender = '';
  String dob = '';
  String whatsappNumber = '';

  // Just enough to label the single "First Consultation" row below - the
  // actual data (dietician-filled questionnaire answers) is rendered by
  // the existing ViewFirstConsultationView, which this row navigates to,
  // rather than duplicating that rendering inline here.
  bool hasConsultation = false;

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  Future<void> _loadAccountInfo() async {
    final results = await Future.wait([
      service.getUserInfo(),
      _consultationService.getMyConsultation(silent: true),
    ]);
    final response = results[0];
    final consultationResponse = results[1];

    if (response != null && response['data'] != null) {
      final user = response['data'];
      final profile = user['profile'] ?? {};

      setState(() {
        fullName = profile['fullName'] ?? '';
        email = user['email'] ?? '';
        gender = profile['gender'] ?? '';
        whatsappNumber = profile['whatsappNumber'] ?? '';
        hasConsultation = consultationResponse?['data'] != null;

        final rawDate = profile['dateOfBirth'];
        if (rawDate != null && rawDate.toString().isNotEmpty) {
          try {
            final date = DateTime.parse(rawDate);
            dob =
                "${date.day.toString().padLeft(2, '0')}/"
                "${date.month.toString().padLeft(2, '0')}/"
                "${date.year}";
          } catch (_) {}
        }

        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: const CustomText(
          text: 'Account',
          fontWeight: FontWeight.w500,
          fontSize: 19,
          color: Color(0xff851653),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Profile avatar + name ---
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xff851653), Color(0xffB8477A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xff851653,
                                ).withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.roboto(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomText(
                          text: fullName.isNotEmpty ? fullName : '--',
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: const Color(0xff1F2A37),
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          text: email,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: const Color(0xff6B7280),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Personal Information card ---
                  _sectionLabel('Personal Information'),
                  const SizedBox(height: 10),
                  _card([
                    _iconRow(Icons.person_outline, 'Full Name', fullName),
                    _iconRow(Icons.email_outlined, 'Email', email),
                    _iconRow(
                      gender == 'Male'
                          ? Icons.male
                          : gender == 'Female'
                          ? Icons.female
                          : Icons.transgender,
                      'Gender',
                      gender,
                    ),
                    _iconRow(Icons.cake_outlined, 'Date of Birth', dob),
                    _iconRow(Icons.phone_outlined, 'WhatsApp', whatsappNumber),
                  ]),

                  const SizedBox(height: 20),

                  // --- First Consultation (single item -> full read-only
                  // view, same data ViewFirstConsultationView already
                  // shows from Home) ---
                  _sectionLabel('First Consultation'),
                  const SizedBox(height: 10),
                  _card([
                    _actionRow(
                      Icons.assignment_outlined,
                      hasConsultation
                          ? 'First Consultation'
                          : 'First Consultation (not completed yet)',
                      hasConsultation
                          ? const Color(0xff851653)
                          : const Color(0xff9DA4AE),
                      () => Get.to(() => const ViewFirstConsultationView()),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // --- Subscription card ---
                  _sectionLabel('Subscription'),
                  const SizedBox(height: 10),
                  _buildSubscriptionCard(),

                  const SizedBox(height: 24),

                  // --- Actions ---
                  _sectionLabel('Settings'),
                  const SizedBox(height: 10),
                  _card([
                    _actionRow(
                      Icons.lock_outline,
                      'Change Password',
                      const Color(0xff851653),
                      _showChangePasswordDialog,
                    ),
                    _actionRow(
                      Icons.delete_outline,
                      'Delete Account',
                      const Color(0xffDC2626),
                      _showDeleteConfirmation,
                    ),
                  ]),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return CustomText(
      text: text,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: const Color(0xff6B7280),
    );
  }

  Widget _card(List<Widget> children) {
    final filtered = children
        .where((w) => w is! SizedBox || (w).height != 0)
        .toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < filtered.length; i++) ...[
            filtered[i],
            if (i < filtered.length - 1)
              const Divider(height: 1, indent: 56, color: Color(0xffF3F4F6)),
          ],
        ],
      ),
    );
  }

  Widget _iconRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox(height: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xffFDF2FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xff851653)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff9DA4AE),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff1F2A37),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final homeController = Get.find<HomeController>();

    return Obx(() {
      final status = homeController.requestStatus.value;
      final expiresAt = homeController.subscriptionExpiresAt.value;
      final startDate = homeController.subscriptionStartDate.value;

      // No subscription yet - PartiallyPaid still has an activated plan
      // (see backend activateDietPlan), just with a balance owed.
      final isActivated = status == 'Paid' || status == 'PartiallyPaid';
      if (!isActivated || expiresAt == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: cardBorder,
            boxShadow: cardShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xffF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.card_membership_outlined,
                  size: 24,
                  color: Color(0xff9DA4AE),
                ),
              ),
              const SizedBox(height: 12),
              const CustomText(
                text: 'No Active Subscription',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xff4D5761),
              ),
              const SizedBox(height: 4),
              const CustomText(
                text: 'Subscribe to get your personalized diet plan',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xff9DA4AE),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      final isExpired = homeController.isSubscriptionExpired;
      final daysLeft = homeController.daysRemaining;
      final expiryFormatted = DateFormat('dd MMM yyyy').format(expiresAt);
      final startFormatted = startDate != null
          ? DateFormat('dd MMM yyyy').format(startDate)
          : '--';
      final accent = isExpired
          ? const Color(0xffDC2626)
          : const Color(0xff16A34A);
      final bgColor = isExpired
          ? const Color(0xffFEF2F2)
          : const Color(0xffF0FDF4);

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: cardBorder,
          boxShadow: cardShadow,
        ),
        child: Column(
          children: [
            // header strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isExpired
                          ? Icons.cancel_outlined
                          : Icons.verified_outlined,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpired
                              ? 'Subscription Expired'
                              : 'Subscription Active',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: accent,
                          ),
                        ),
                        if (!isExpired)
                          Text(
                            '$daysLeft days remaining',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: accent.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _subscriptionRow(
                    'Plan',
                    homeController.selectedPlanName.value.isNotEmpty
                        ? homeController.selectedPlanName.value
                        : '--',
                  ),
                  const SizedBox(height: 10),
                  _subscriptionRow(
                    'Amount',
                    homeController.selectedPlanAmount.value > 0
                        ? '\u20b9${homeController.selectedPlanAmount.value.toStringAsFixed(0)}'
                        : '--',
                  ),
                  const SizedBox(height: 10),
                  _subscriptionRow('Started', startFormatted),
                  const SizedBox(height: 10),
                  _subscriptionRow('Expires', expiryFormatted),
                  if (status == 'PartiallyPaid' &&
                      homeController.latestAmountPending.value > 0) ...[
                    const SizedBox(height: 10),
                    _subscriptionRow(
                      'Balance Due',
                      '₹${homeController.latestAmountPending.value.toStringAsFixed(0)}',
                      valueColor: const Color(0xffC2410C),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _subscriptionRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xff9DA4AE),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? const Color(0xff1F2A37),
          ),
        ),
      ],
    );
  }

  // Shared branded input decoration for dialogs
  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xff4D5761)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xffEAD4E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff851653), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final isLoading = false.obs;

    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: const CustomText(
          text: 'Change Password',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Color(0xff530630),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomField(
                  space: false,
                  hide: true,
                  lable: 'Current Password',
                  controller: currentPasswordController,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your current password'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomField(
                  space: false,
                  hide: true,
                  lable: 'New Password',
                  controller: newPasswordController,
                  validator: (value) => validatePassword(value),
                ),
                const SizedBox(height: 16),
                CustomField(
                  space: false,
                  hide: true,
                  lable: 'Confirm New Password',
                  controller: confirmPasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != newPasswordController.text) {
                      return 'New passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        isOutline: true,
                        outlineButtonColor: const Color(0xff851653),
                        textColor: const Color(0xff851653),
                        text: 'Cancel',
                        onTap: () => Get.back(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => CustomButton(
                          isOutline: false,
                          buttonColor: const Color(0xff851653),
                          text: 'Update',
                          isLoading: isLoading.value,
                          onTap: () async {
                            if (!formKey.currentState!.validate()) return;
                            isLoading.value = true;
                            await _changePassword(
                              currentPasswordController.text.trim(),
                              newPasswordController.text.trim(),
                            );
                            isLoading.value = false;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ).whenComplete(() {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
      isLoading.close();
    });
  }

  /// Reauthenticates with the current password, sets the new one, and signs
  /// out every other session on the account - all in one call to the
  /// backend's /auth/change-password (see docwellness-backend's
  /// authController.js), which now holds the only Supabase credentials this
  /// app's auth flow ever touches.
  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await AuthService().changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (response['success'] != true) {
        showAppToast(
          Get.overlayContext!,
          message: response['message'] ?? 'Current password is incorrect',
          type: AppToastType.error,
        );
        return;
      }

      Get.back(); // close dialog
      showAppToast(
        Get.overlayContext!,
        message: 'Password changed successfully',
        type: AppToastType.success,
      );
    } catch (e) {
      showAppToast(
        Get.overlayContext!,
        message: 'Something went wrong. Please try again.',
        type: AppToastType.error,
      );
    }
  }

  void _showDeleteConfirmation() {
    final passwordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is permanent and cannot be undone. Enter your password to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: _dialogInputDecoration('Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) {
                showAppToast(
                  Get.overlayContext!,
                  message: 'Please enter your password',
                  type: AppToastType.error,
                );
                return;
              }
              await _deleteAccount(password);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    ).whenComplete(passwordController.dispose);
  }

  Future<void> _deleteAccount(String password) async {
    try {
      final apiService = ApiService();
      final response = await apiService.request(
        endPoint: '/profile',
        method: 'DELETE',
        data: {'password': password},
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        // Disconnect socket
        try {
          final socketService = Get.find<SocketService>();
          socketService.disconnect();
        } catch (_) {}

        final pref = await SharedPreferences.getInstance();
        await pref.clear();
        token = null;
        userId = null;
        role = null;

        Get.back(); // close dialog
        showAppToast(
          Get.overlayContext!,
          message: 'Your account has been deleted.',
          type: AppToastType.success,
        );
        Get.offAllNamed(Routes.AUTH);
      } else {
        showAppToast(
          Get.overlayContext!,
          message: response?.data?['message'] ?? 'Failed to delete account',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      showAppToast(
        Get.overlayContext!,
        message: 'Something went wrong. Please try again.',
        type: AppToastType.error,
      );
    }
  }
}
