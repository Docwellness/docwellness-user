import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
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
  bool isLoading = true;
  String fullName = '';
  String email = '';
  String gender = '';
  String dob = '';
  String whatsappNumber = '';
  String primaryGoal = '';
  String weight = '';
  String height = '';

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  Future<void> _loadAccountInfo() async {
    final response = await service.getUserInfo();
    if (response != null && response['data'] != null) {
      final user = response['data'];
      final profile = user['profile'] ?? {};
      final health = user['healthProfile'] ?? {};

      setState(() {
        fullName = profile['fullName'] ?? '';
        email = user['email'] ?? '';
        gender = profile['gender'] ?? '';
        whatsappNumber = profile['whatsappNumber'] ?? '';
        primaryGoal = health['primaryGoal'] ?? '';
        weight = (health['weight'] ?? '').toString();
        height = (health['height'] ?? '').toString();

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

                  // --- Health Profile card ---
                  _sectionLabel('Health Profile'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          Icons.monitor_weight_outlined,
                          'Weight',
                          weight.isNotEmpty ? '$weight kg' : '--',
                          const Color(0xff3B82F6),
                          const Color(0xffEFF6FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          Icons.height,
                          'Height',
                          height.isNotEmpty ? '$height cm' : '--',
                          const Color(0xff8B5CF6),
                          const Color(0xffF5F3FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          Icons.flag_outlined,
                          'Goal',
                          primaryGoal.isNotEmpty
                              ? primaryGoal.replaceAll(' ', '\n')
                              : '--',
                          const Color(0xffF59E0B),
                          const Color(0xffFFFBEB),
                        ),
                      ),
                    ],
                  ),

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
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

  Widget _statCard(
    IconData icon,
    String label,
    String value,
    Color accent,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: accent),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xff6B7280),
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

      // No subscription yet
      if (status != 'Paid' || expiresAt == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
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
                  _subscriptionRow('Plan', 'Monthly (30 days)'),
                  const SizedBox(height: 10),
                  _subscriptionRow('Amount', '\u20b92500/month'),
                  const SizedBox(height: 10),
                  _subscriptionRow('Started', startFormatted),
                  const SizedBox(height: 10),
                  _subscriptionRow('Expires', expiryFormatted),
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
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: _dialogInputDecoration('Current Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: _dialogInputDecoration('New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: _dialogInputDecoration('Confirm New Password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final current = currentPasswordController.text.trim();
              final newPass = newPasswordController.text.trim();
              final confirm = confirmPasswordController.text.trim();

              if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                Get.snackbar(
                  'Error',
                  'All fields are required',
                  backgroundColor: Colors.red.shade50,
                  colorText: Colors.red.shade900,
                );
                return;
              }
              if (newPass.length < 6) {
                Get.snackbar(
                  'Error',
                  'New password must be at least 6 characters',
                  backgroundColor: Colors.red.shade50,
                  colorText: Colors.red.shade900,
                );
                return;
              }
              if (newPass != confirm) {
                Get.snackbar(
                  'Error',
                  'New passwords do not match',
                  backgroundColor: Colors.red.shade50,
                  colorText: Colors.red.shade900,
                );
                return;
              }

              await _changePassword(current, newPass);
            },
            child: Text(
              'Update',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final apiService = ApiService();
      final response = await apiService.request(
        endPoint: '/auth/change-password',
        method: 'PUT',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        // Update stored token if backend returns a new one
        final newToken = response.data['data']?['token'];
        if (newToken != null) {
          token = newToken;
          final pref = await SharedPreferences.getInstance();
          await pref.setString('token', newToken);
        }

        Get.back(); // close dialog
        Get.snackbar(
          'Success',
          'Password changed successfully',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
        );
      } else {
        Get.snackbar(
          'Error',
          response?.data?['message'] ?? 'Failed to change password',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade900,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
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
                Get.snackbar(
                  'Error',
                  'Please enter your password',
                  backgroundColor: Colors.red.shade50,
                  colorText: Colors.red.shade900,
                );
                return;
              }
              await _deleteAccount(password);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        Get.snackbar(
          'Account Deleted',
          'Your account has been deleted.',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
        );
        Get.offAllNamed(Routes.AUTH);
      } else {
        Get.snackbar(
          'Error',
          response?.data?['message'] ?? 'Failed to delete account',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade900,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
    }
  }
}
