import 'package:docwellness/app/modules/auth/widgets/bmi_container.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/widgets/personal_info_bottom_sheets.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_datepicker.dart';
import 'package:docwellness/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:docwellness/utils/functions/goal_weight_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MainRequestDietPlanView extends StatefulWidget {
  const MainRequestDietPlanView({super.key});

  @override
  State<MainRequestDietPlanView> createState() =>
      _MainRequestDietPlanViewState();
}

class _MainRequestDietPlanViewState extends State<MainRequestDietPlanView> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final HomeController controller = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    // Defer past the current build/frame: getRequestUserInfo() mutates Rx
    // fields (starting with isRequestDietPlanLoading) before its first
    // await, which otherwise fires during this widget's own first build.
    // Harmless in isolation, but when another screen (e.g. OrderSummaryView)
    // stays mounted underneath with its own Obx watching the same
    // HomeController fields, that reentrant update was hanging the UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getRequestUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        titleSpacing: 0,
        title: CustomText(
          text: 'Request Diet Plan',
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
      ),
      body: Obx(
        () => controller.isRequestDietPlanLoading.value
            ? Center(child: CircularProgressIndicator())
            : _buildRequestForm(),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            children: [
              SizedBox(height: 16),
              DatePickerField(
                suffixIconColor: Color(0xff1E1E1E),
                label: "Start Date for Diet",
                controller: controller.requestUserStartDate,
                // Tomorrow as first selectable date
                firstDate: DateTime.now().add(const Duration(days: 1)),
                // One month from tomorrow as last selectable date
                lastDate: DateTime.now().add(const Duration(days: 31)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please select start date";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Center(
                child: CustomText(
                  text: 'Personal Information',
                  fontWeight: FontWeight.w500,
                  fontSize: 19,
                  color: Color(0xff851653),
                ),
              ),
              SizedBox(height: 16),
              CustomField(
                lable: 'Full name',
                controller: controller.requestUserName,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter name";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DatePickerField(
                      suffixIconColor: Color(0xff530630),
                      label: 'Date of Birth',
                      controller: controller.requestUserDob,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Required";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Obx(() {
                      return CustomDropdown(
                        label: 'Gender',
                        items: const ["Male", "Female", "Other"],
                        value: controller.selectedGender.value.isEmpty
                            ? null
                            : controller.selectedGender.value,

                        onChanged: (val) {
                          controller.setGender(val!);
                        },
                        isRounded: false,
                        suffixIconColor: Color(0xff530630),
                      );
                    }),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Obx(() {
                return CustomDropdown(
                  label: 'Primary Goal',
                  items: primaryGoalOptions,
                  value: controller.selectedGoal.value.isEmpty
                      ? null
                      : controller.selectedGoal.value,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Please select primary goal";
                    }
                    return null;
                  },
                  onChanged: (val) {
                    controller.selectedGoal.value = val!;
                  },
                  isRounded: false,
                  suffixIconColor: Color(0xff530630),
                );
              }),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomField(
                      keyboardType: TextInputType.number,
                      onChange: (e) {
                        controller.updateBMI();
                      },
                      lable: "Initial",
                      unitSuffix: 'Kg',
                      controller: controller.requestUserWeight,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter weight";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: CustomField(
                      keyboardType: TextInputType.number,
                      onChange: (e) {
                        controller.updateBMI();
                      },
                      lable: "Height",
                      unitSuffix: 'CM',
                      controller: controller.requestUserHeight,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter height";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: CustomField(
                      keyboardType: TextInputType.number,
                      onChange: (e) {
                        controller.updateTargetWeight();
                      },
                      lable: "Target",
                      unitSuffix: 'Kg',
                      controller: controller.requestTargetWeight,
                      // The goal-vs-weight mismatch message is shown as a
                      // toast on submit instead of returned here - it's too
                      // long to fit cleanly as inline text in this narrow,
                      // one-of-three-in-a-row field.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter target weight";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Obx(
                () => _buildPickerField(
                  label: 'Illness Attention',
                  value: controller.illness.join(', '),
                  onTap: () async {
                    final result = await showIllnessAttentionSheet(
                      context,
                      gender: controller.selectedGender.value,
                      selected: controller.illness,
                    );
                    if (result != null) {
                      controller.illness.value = result;
                    }
                  },
                ),
              ),
              SizedBox(height: 16),
              Obx(
                () => _buildPickerField(
                  label: 'Activity Level',
                  value: controller.activityLevel.value,
                  onTap: () async {
                    final result = await showActivityLevelSheet(
                      context,
                      selected: controller.activityLevel.value,
                    );
                    if (result != null) {
                      controller.activityLevel.value = result;
                    }
                  },
                ),
              ),
              SizedBox(height: 16),
              Obx(
                () => BmiContainer(
                  index: controller.bmiIndex.value,
                  value: controller.bmiValue.value,
                  targetedWeight: controller.targetedWeight.value,
                  activityLevel: null,
                  // .toList() (not the bare RxList) so this read happens
                  // inside Obx's tracking window - passing the RxList
                  // reference alone doesn't register a dependency, since
                  // BmiContainer only iterates it later during its own
                  // build(), outside this callback.
                  healthConcerentList: controller.illness.toList(),
                  activityLevelText: controller.activityLevel.value,
                ),
              ),
              SizedBox(height: 16),
              CustomText(
                text:
                    'By clicking on “Select Plan”, you agree to share the true information filled on this screen. You consider yourself liable for all the information you shared.',
                fontWeight: FontWeight.w400,
                fontSize: 11.5,
                color: Color(0xff4D5761),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Obx(
                () => CustomButton(
                  isLoading: controller.isSendRequestLoading.value,
                  onTap: () async {
                    if (!_key.currentState!.validate()) {
                      return;
                    }
                    final target = double.tryParse(
                      controller.requestTargetWeight.text,
                    );
                    final initial = double.tryParse(
                      controller.requestUserWeight.text,
                    );
                    final heightCm = double.tryParse(
                      controller.requestUserHeight.text,
                    );
                    if (target != null && initial != null) {
                      final mismatch = validateGoalWeights(
                        goal: controller.selectedGoal.value,
                        initialWeight: initial,
                        targetWeight: target,
                        heightCm: heightCm,
                      );
                      if (mismatch != null) {
                        showAppToast(
                          context,
                          message: mismatch,
                          type: AppToastType.warning,
                        );
                        return;
                      }
                    }
                    await controller.sendRequestDietPlan();
                  },
                  text: 'Select Plan',
                  isOutline: false,
                ),
              ),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  /// Read-only, tap-to-open field styled like CustomField, used for the
  /// Illness Attention / Activity Level pickers whose values come from a
  /// bottom sheet rather than direct text entry.
  Widget _buildPickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final hasValue = value.trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          label: hasValue
              ? Container(
                  height: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF6FB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: CustomText(
                    text: label,
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: const Color(0xff851653),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff4D5761),
                  ),
                ),
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xff6C737F),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: hasValue
                  ? const Color(0xff530630)
                  : const Color(0xff6C737F),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: hasValue
                  ? const Color(0xff530630)
                  : const Color(0xff6C737F),
            ),
          ),
        ),
        child: Text(
          hasValue ? value : '',
          style: GoogleFonts.roboto(
            color: const Color(0xff530630),
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
