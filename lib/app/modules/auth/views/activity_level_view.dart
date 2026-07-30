import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/health_concerns_view.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActivityLevelView extends StatefulWidget {
  // true when opened via the "edit" row on SummaryView - Next then returns
  // straight back to Summary instead of continuing on to HealthConcernsScreen.
  final bool isEditing;

  const ActivityLevelView({super.key, this.isEditing = false});

  @override
  State<ActivityLevelView> createState() => _ActivityLevelViewState();
}

// Shared with the "Activity Level" bottom sheet reused in the Request Diet
// Plan screen's personal info update, so both places show the same options.
const List<Map<String, String>> activityLevelOptions = [
  {
    'title': 'Sedentary',
    'subtitle': 'I spend most of my day sitting',
    'image': 'assets/levels/Group.png',
  },
  {
    'title': 'Lightly Activity',
    'subtitle': 'I have made doing exercise a lasting habit',
    'image': 'assets/levels/Group1.png',
  },
  {
    'title': 'Moderately Activity',
    'subtitle': 'I work on my feet and move around throughout the day',
    'image': 'assets/levels/Group2.png',
  },
  {
    'title': 'Very Active',
    'subtitle': 'I spend most of my day doing physical activities',
    'image': 'assets/levels/Group3.png',
  },
];

class _ActivityLevelViewState extends State<ActivityLevelView> {
  final List activityLevelList = activityLevelOptions;

  // Guarded like personal_info_view.dart's controller field - this screen
  // can be reached as the app-restart resume entry point (saved onboarding
  // draft, profile incomplete) where nothing has registered AuthController
  // yet, not just via the normal onboarding flow.
  final AuthController controller = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  late int? selected;

  @override
  void initState() {
    super.initState();
    // Pre-select whatever AuthController already holds - matters both when
    // revisiting via "edit" from Summary, and when this screen resumes a
    // saved onboarding draft after an app restart.
    selected = controller.activityLevel.value;
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
          text: 'What’s your activity level?',
          fontWeight: FontWeight.w400,
          fontSize: 20,
          color: Color(0xff851653),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40),
              ListView.builder(
                itemCount: activityLevelList.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final data = activityLevelList[index];
                  final isSelected = selected == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selected = index;
                        });
                      },
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected == true
                              ? Color(0xffFEF6FB)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected == true
                                ? Color(0xffFCFCFD)
                                : Color(0xffF9FAFB),
                          ),
                          boxShadow: cardShadow,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 32, right: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 73.28,
                                width: 40.22,
                                child: Image.asset(data['image']),
                              ),
                              SizedBox(width: 22),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: data['title'],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      color: Color(0xff851653),
                                    ),
                                    SizedBox(height: 4),
                                    CustomText(
                                      text: data['subtitle'],
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Color(0xff4D5761),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 32),
              CustomButton(
                onTap: () async {
                  if (selected != null) {
                    controller.activityLevel.value = selected!;
                    await controller.saveOnboardingDraft();
                    if (widget.isEditing) {
                      Get.back();
                    } else {
                      Get.to(() => HealthConcernsScreen());
                    }
                  }
                },
                text: widget.isEditing ? 'Save' : 'Next',
                isOutline: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
