import 'package:docwellness/app/modules/auth/widgets/bmi_container.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_datepicker.dart';
import 'package:docwellness/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    controller.getRequestUserInfo();
    super.initState();
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
                      hintText: 'Date of Birth',
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
                        hintText: 'Gender',
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
              Row(
                children: [
                  Expanded(
                    child: CustomField(
                      onChange: (e) {
                        controller.updateBMI();
                      },
                      hintText: "Weight",
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
                    child: Obx(() {
                      return CustomDropdown(
                        hintText: 'Height',
                        items: List.generate(280, (index) => "${index + 1} CM"),
                        value: controller.selectedHeight.value.isEmpty
                            ? null
                            : controller.selectedHeight.value,

                        onChanged: (val) {
                          controller.updateBMI();
                          controller.selectedHeight.value = val!;
                        },
                        isRounded: false,
                        suffixIconColor: Color(0xff530630),
                      );
                    }),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Obx(
                () => BmiContainer(
                  index: controller.bmiIndex.value,
                  value: controller.bmiValue.value,
                  targetedWeight: controller.targetedWeight.value,
                  activityLevel: null,
                  healthConcerentList: controller.illness,
                  activityLevelText: controller.activityLevel.value,
                ),
              ),
              SizedBox(height: 16),
              CustomText(
                text:
                    'By clicking on “Submit Request”, you agree to share the true information filled on this screen. You consider yourself liable for all the information you shared.',
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
                    if (_key.currentState!.validate()) {
                      await controller.sendRequestDietPlan();
                    }
                  },
                  text: 'Submit Request',
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
}
