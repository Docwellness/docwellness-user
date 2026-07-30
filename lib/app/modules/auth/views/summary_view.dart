import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/activity_level_view.dart';
import 'package:docwellness/app/modules/auth/views/health_concerns_view.dart';
import 'package:docwellness/app/modules/auth/views/personal_info_view.dart';
import 'package:docwellness/app/modules/auth/views/target_weight_view.dart';
import 'package:docwellness/app/modules/auth/widgets/bmi_container.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SummaryView extends StatelessWidget {
  SummaryView({super.key});
  // Guarded like personal_info_view.dart's controller field - avoids a
  // "not found" crash if this screen is ever reached without AuthController
  // already registered (e.g. hot reload/restart mid-flow).
  final AuthController controller = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  String get _activityLevelLabel {
    final title = activityLevelOptions[controller.activityLevel.value]['title'];
    return title ?? '';
  }

  // Each row re-opens the corresponding onboarding screen (isEditing: true)
  // so the user can fix an earlier answer without restarting the whole
  // flow - AuthController is permanent (see auth_binding.dart), and every
  // screen's "Save"/"Next" already saves the running draft, so re-entering
  // here with existing values pre-filled and returning (Get.back) straight
  // to this same Summary instance just works.
  Widget _editRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xffFCE7F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: const Color(0xff851653)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xff1F2A37),
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    text: subtitle,
                    fontWeight: FontWeight.w400,
                    fontSize: 12.5,
                    color: const Color(0xff6C737F),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xff9DA4AE)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        titleSpacing: 16,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'Summary',
          fontWeight: FontWeight.w400,
          fontSize: 20,
          color: Color(0xff851653),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: cardBorder,
                        boxShadow: cardShadow,
                      ),
                      child: Column(
                        children: [
                          _editRow(
                            icon: Icons.person_outline,
                            title: 'Personal Information',
                            subtitle: controller.nameController.text.isNotEmpty
                                ? controller.nameController.text
                                : 'Tap to review',
                            onTap: () => Get.to(
                              () => const PersonalInfoView(isEditing: true),
                            ),
                          ),
                          const Divider(height: 1),
                          _editRow(
                            icon: Icons.monitor_weight_outlined,
                            title: 'Target Weight',
                            subtitle:
                                controller.selectedTargetWeight.value.isNotEmpty
                                ? controller.selectedTargetWeight.value
                                : 'Not set',
                            onTap: () =>
                                Get.to(() => TargetWeightView(isEditing: true)),
                          ),
                          const Divider(height: 1),
                          _editRow(
                            icon: Icons.directions_run,
                            title: 'Activity Level',
                            subtitle: _activityLevelLabel,
                            onTap: () =>
                                Get.to(() => ActivityLevelView(isEditing: true)),
                          ),
                          const Divider(height: 1),
                          _editRow(
                            icon: Icons.favorite_border,
                            title: 'Health Concerns',
                            subtitle: controller.healthConcerns.isNotEmpty
                                ? controller.healthConcerns.join(', ')
                                : 'Not set',
                            onTap: () => Get.to(
                              () => HealthConcernsScreen(isEditing: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  CustomText(
                    text: 'Personal summary based on your answers',
                    fontWeight: FontWeight.w500,
                    fontSize: 19,
                    color: Color(0xff851653),
                    textAlign: TextAlign.center,
                    height: 1.2,
                  ),
                  SizedBox(height: 25),
                  Obx(
                    () => BmiContainer(
                      index: controller.bmiIndex.value,
                      value: controller.bmi.value,
                      targetedWeight: controller.selectedTargetWeight.value,
                      activityLevel: controller.activityLevel.value,
                      healthConcerentList: controller.healthConcerns.toList(),
                    ),
                  ),
                  SizedBox(height: 25),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
            child: Obx(
              () => CustomButton(
                isLoading: controller.isRegistering.value,
                onTap: () => controller.completeRegistration(),
                text: 'Submit',
                isOutline: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
