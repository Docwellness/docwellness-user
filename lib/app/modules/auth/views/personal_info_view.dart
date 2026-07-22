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
  // true when opened via the "edit" row on SummaryView - Next then returns
  // straight back to Summary instead of continuing the forward onboarding
  // chain to TargetWeightView.
  final bool isEditing;

  const PersonalInfoView({super.key, this.isEditing = false});

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  // Signup/email verification (SignUpView) now runs before this screen and
  // already registered AuthController - but this screen is also the resume
  // entry point after an app restart (session confirmed, profile
  // incomplete - see main.dart/SplashView), where nothing has registered it
  // yet. Guard against clobbering the former case while still covering the
  // latter. permanent: true so it can't be disposed by route churn (e.g.
  // AuthController.login()'s Get.offAll on the way to this exact screen).
  final AuthController controller = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _restoreState();
  }

  Future<void> _restoreState() async {
    await controller.loadUserData();
    await controller.restoreOnboardingDraft();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 16,
        // No back button - this screen follows email verification (and is
        // also the resume entry point after an app restart mid-onboarding,
        // see SplashView), so there's nothing earlier in the stack it
        // should let the user return to.
        automaticallyImplyLeading: false,
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
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      await controller.saveOnboardingDraft();
                      if (widget.isEditing) {
                        Get.back();
                      } else {
                        Get.to(() => TargetWeightView());
                      }
                    }
                  },
                  text: widget.isEditing ? 'Save' : 'Next',
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
