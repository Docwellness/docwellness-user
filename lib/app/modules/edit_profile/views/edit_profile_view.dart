import 'package:docwellness/app/modules/auth/widgets/weight_bmi_container.dart';
import 'package:docwellness/app/modules/edit_profile/controllers/edit_profile_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_datepicker.dart';
import 'package:docwellness/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:docwellness/utils/common_widgets/phone_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

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
          text: 'Edit Profile',
          fontWeight: FontWeight.w400,
          fontSize: 19,
          color: Color(0xff851653),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final editable = controller.canEdit.value;

        return Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Locked banner when diet request submitted
                  if (!editable)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF3CD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xffFFEEBA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Color(0xff856404),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomText(
                              text:
                                  'Profile editing is locked after diet request submission.',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff856404),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Wrap form fields so they become non-interactive when locked
                  IgnorePointer(
                    ignoring: !editable,
                    child: Opacity(
                      opacity: editable ? 1.0 : 0.5,
                      child: Column(
                        children: [
                          /// FULL NAME
                          CustomField(
                            keyboardType: TextInputType.text,
                            lable: 'Full name',
                            controller: controller.nameController,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Full name is required";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              /// GENDER DROPDOWN
                              Expanded(
                                child: Obx(() {
                                  return CustomDropdown(
                                    suffixIconColor: const Color(0xff0D121C),
                                    isRounded: false,
                                    label: "Gender",
                                    items: const ["Male", "Female", "Other"],
                                    value:
                                        controller.selectedGender.value.isEmpty
                                        ? null
                                        : controller.selectedGender.value,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return "Please select gender";
                                      }
                                      return null;
                                    },
                                    onChanged: (val) =>
                                        controller.setGender(val!),
                                  );
                                }),
                              ),

                              const SizedBox(width: 16),

                              /// DOB FIELD
                              Expanded(
                                child: DatePickerField(
                                  label: "Date of Birth",
                                  controller: controller.ageController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Required";
                                    }
                                    try {
                                      final parts = value.split('/');
                                      if (parts.length == 3) {
                                        final dob = DateTime(
                                          int.parse(parts[2]),
                                          int.parse(parts[1]),
                                          int.parse(parts[0]),
                                        );
                                        final now = DateTime.now();
                                        int age = now.year - dob.year;
                                        if (now.month < dob.month ||
                                            (now.month == dob.month &&
                                                now.day < dob.day)) {
                                          age--;
                                        }
                                        if (age < 16) {
                                          return "Must be 16 or older";
                                        }
                                      }
                                    } catch (_) {}
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              /// WEIGHT
                              Expanded(
                                child: CustomField(
                                  keyboardType: TextInputType.number,
                                  onChange: (_) => controller.updateBMI(),
                                  lable: 'Weight (in KG)',
                                  controller: controller.weightController,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Enter weight";
                                    }
                                    if (double.tryParse(v) == null) {
                                      return "Enter valid number";
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(width: 16),

                              /// HEIGHT
                              Expanded(
                                child: CustomField(
                                  keyboardType: TextInputType.number,
                                  isPoint: true,
                                  onChange: (_) => controller.updateBMI(),
                                  lable: 'Height in cm',
                                  controller: controller.heightController,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Enter height";
                                    }
                                    if (double.tryParse(v) == null) {
                                      return "Enter valid number";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// WHATSAPP NUMBER
                          PhoneField(
                            controller: controller.numberController,
                            enabled: editable,
                            validator: (v) {
                              final digits =
                                  v?.replaceAll(RegExp(r'\D'), '') ?? '';
                              if (digits.isEmpty)
                                return 'Enter WhatsApp number';
                              if (digits.length < 7)
                                return 'Enter valid number';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// EMAIL
                          CustomField(
                            keyboardType: TextInputType.emailAddress,
                            lable: 'Email Address',
                            controller: controller.emailController,
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Enter email";
                              if (!GetUtils.isEmail(v)) {
                                return "Enter valid email";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// PRIMARY GOAL
                          Obx(() {
                            return CustomDropdown(
                              isRounded: true,
                              suffixIconColor: const Color(0xff1E1E1E),
                              label: "Primary Goal",
                              items: const ["Weight Loss", "Weight Gain"],
                              value: controller.selectedPG.value.isEmpty
                                  ? null
                                  : controller.selectedPG.value,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return "Please select primary goal";
                                }
                                return null;
                              },
                              onChanged: (val) => controller.setPG(val!),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Obx(() {
                    return WeightBmiContainer(
                      index: controller.bmiIndex.value,
                      bmi: controller.bmi.value,
                    );
                  }),

                  const SizedBox(height: 32),

                  Obx(() {
                    return CustomButton(
                      onTap: editable && !controller.isSaving.value
                          ? () {
                              if (formKey.currentState!.validate()) {
                                controller.saveProfile();
                              }
                            }
                          : () {},
                      text: controller.isSaving.value ? 'Saving...' : 'Save',
                      isOutline: !editable,
                      textColor: editable ? null : const Color(0xff9DA4AE),
                      outlineButtonColor: editable
                          ? null
                          : const Color(0xffE5E7EB),
                    );
                  }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
