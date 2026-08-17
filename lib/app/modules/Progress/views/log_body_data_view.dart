import 'dart:io';

import 'package:docwellness/app/modules/Progress/controllers/progress_controller.dart';
import 'package:docwellness/app/modules/Progress/widgets/small_dropdown.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogBodyDataView extends StatelessWidget {
  final ScrollController scrollController;

  LogBodyDataView({super.key, required this.scrollController});

  final ProgressController controller = Get.find<ProgressController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Color(0xff79747E),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        size: 25,
                        color: Color(0xff1F2A37),
                      ),
                    ),
                    SizedBox(width: 10),
                    CustomText(
                      text: 'Log My Body',
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: Color(0xff1F2A37),
                    ),
                  ],
                ),
              ),
              Spacer(),
              SizedBox(
                height: 40,
                width: 110,
                child: Obx(() {
                  // Only weeks whose checkpoint has actually been reached -
                  // see ProgressController.computeReachedWeeks. A week
                  // that's still in the future has nothing real to log
                  // against yet.
                  final weekItems = controller.reachedWeeks
                      .map((w) => "Week $w")
                      .toList();
                  return CustomDropdown40(
                    horizontalSpace: 9,
                    lableSize: 12,
                    label: "Week",
                    items: weekItems,
                    value: controller.selectLogBodyDay.value.isEmpty
                        ? null
                        : controller.selectLogBodyDay.value,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Please select week";
                      }
                      return null;
                    },
                    onChanged: (val) {
                      controller.setLogBodyDay(val!);
                    },
                  );
                }),
              ),
            ],
          ),

          Divider(color: Color(0xff9DA4AE)),

          const SizedBox(height: 15),

          Obx(() {
            // No weekly checkpoint reached yet (e.g. still in Week 1 before
            // its own checkpoint date) - nothing to log against, so the rest
            // of the form stays hidden rather than letting the patient fill
            // in a week that doesn't exist yet.
            if (controller.reachedWeeks.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CustomText(
                  text:
                      "You'll be able to log body data once your first weekly checkpoint is reached.",
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Color(0xff9DA4AE),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown(
                  isRounded: false,
                  suffixIconColor: Color(0xff0D121C),
                  label: "Parameter",
                  items: ['Weight'],
                  value: controller.selectParameter.value.isEmpty
                      ? null
                      : controller.selectParameter.value,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Please select parameter";
                    }
                    return null;
                  },
                  onChanged: (val) {
                    controller.setParametery(val!);
                  },
                ),
                const SizedBox(height: 16),
                // Single image picker - falls back to the week's
                // already-uploaded photo (if any) until a new one is picked,
                // same "show what's really logged" reasoning as the
                // prefilled Value/measurement fields below.
                GestureDetector(
                  onTap: () => controller.pickBodyImage(),
                  child: Obx(() {
                    final picked = controller.pickedBodyImage.value;
                    final existingUrl = controller.existingBodyImageUrl.value;
                    return Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF6FB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: picked != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(picked.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 180,
                                ),
                              )
                            : existingUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      existingUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 180,
                                    ),
                                  )
                                : Image.asset('assets/icons/camera.png', height: 40),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                CustomField(
                  lable: 'Value',
                  controller: controller.valueController,
                  hintText: 'Add Weight in kg',
                ),
                const SizedBox(height: 16),
                // Body Measurements (optional)
                Row(
                  children: [
                    Expanded(
                      child: CustomField(
                        lable: 'Arm (cm)',
                        controller: controller.armController,
                        hintText: 'Arm',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomField(
                        lable: 'Waist (cm)',
                        controller: controller.waistController,
                        hintText: 'Waist',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomField(
                        lable: 'Hip (cm)',
                        controller: controller.hipController,
                        hintText: 'Hip',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomField(
                  maxLines: 8,
                  lable: 'Description',
                  controller: controller.descriptionController,
                  hintText: 'Add few more words for describing your feeling',
                ),
                const SizedBox(height: 20),
                Obx(() {
                  final isUpdate = controller.editingProgressId.value.isNotEmpty;
                  return CustomButton(
                    enabled: !controller.isLoadingWeekData.value,
                    isLoading: controller.isSubmitting.value,
                    onTap: () async {
                      final success = await controller.submitBodyData();
                      if (success) {
                        Get.back();
                        _showSuccessDialog();
                      }
                    },
                    text: controller.isSubmitting.value
                        ? (isUpdate ? 'Updating...' : 'Uploading...')
                        : (isUpdate ? 'Update Logged Data' : 'Submit Logged Data'),
                    isOutline: false,
                    fontSize: 14,
                  );
                }),
              ],
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Uses Get.dialog (GetX's own root-navigator overlay) instead of
  // showDialog(context: ...) - the caller pops this whole screen via
  // Get.back() right before calling this, which made the outer context's
  // route (and therefore anything shown via showDialog(context: context))
  // unstable: the delayed auto-dismiss below crashed in production
  // ("Looking up a deactivated widget's ancestor is unsafe") once that
  // route finished tearing down before the 3s timer fired. Get.dialog isn't
  // tied to any specific screen's element tree, so it isn't affected by
  // this screen's own pop.
  void _showSuccessDialog() {
    Get.dialog(_SuccessDialog(), barrierDismissible: false);
    Future.delayed(const Duration(seconds: 3), () {
      if (Get.isDialogOpen == true) Get.back();
    });
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: Color(0xff530630),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            CustomText(
              text: 'Success!',
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Color(0xff530630),
            ),
            const SizedBox(height: 8),
            CustomText(
              text: 'Your body data has been\nlogged successfully',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xff49454F),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff530630),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: () => Get.back(),
                child: Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
