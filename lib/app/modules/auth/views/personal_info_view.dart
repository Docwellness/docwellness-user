import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/target_weight_view.dart';
import 'package:docwellness/app/modules/auth/widgets/weight_bmi_container.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_datepicker.dart';
import 'package:docwellness/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:docwellness/utils/common_widgets/phone_field.dart';
import 'package:docwellness/utils/functions/goal_weight_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalInfoView extends StatefulWidget {
  const PersonalInfoView({super.key});

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  final AuthController controller = Get.put(AuthController());
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller.loadUserData();
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
          text: 'Personal Information',
          fontWeight: FontWeight.w400,
          fontSize: 19,
          color: Color(0xff851653),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                /// FULL NAME
                SizedBox(height: 10),
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
                          suffixIconColor: Color(0xff0D121C),
                          isRounded: false,
                          label: "Gender",
                          items: const ["Male", "Female", "Other"],
                          value: controller.selectedGender.value.isEmpty
                              ? null
                              : controller.selectedGender.value,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please select gender";
                            }
                            return null;
                          },
                          onChanged: (val) {
                            controller.setGender(val!);
                          },
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
                          // Parse dd/mm/yyyy and check age >= 16
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
                  validator: (v) {
                    if (v == null ||
                        v.replaceAll(RegExp(r'[+\d]'), '').isEmpty) {
                      // strip dial code and check remaining digits
                    }
                    final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.isEmpty) return 'Enter WhatsApp number';
                    if (digits.length < 7) return 'Enter valid number';
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
                    if (!GetUtils.isEmail(v)) return "Enter valid email";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// SECOND GENDER DROPDOWN
                Obx(() {
                  return CustomDropdown(
                    isRounded: true,
                    suffixIconColor: Color(0xff1E1E1E),
                    label: "Primary Goal",
                    items: primaryGoalOptions,
                    value: controller.selectedPG.value.isEmpty
                        ? null
                        : controller.selectedPG.value,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Please select primary goal";
                      }
                      return null;
                    },
                    onChanged: (val) {
                      controller.setPG(val!);
                    },
                  );
                }),
                SizedBox(height: 16),
                Obx(() {
                  return WeightBmiContainer(
                    index: controller.bmiIndex.value,
                    bmi: controller.bmi.value,
                  );
                }),

                SizedBox(height: 32),
                CustomButton(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      Get.to(() => TargetWeightView());
                    }
                  },
                  text: 'Next',
                  isOutline: false,
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
