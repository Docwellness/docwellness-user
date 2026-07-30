import 'package:docwellness/app/modules/auth/widgets/bmi_range_bar.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/constants/reference_links.dart';
import 'package:docwellness/utils/functions/link_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BmiContainer extends StatelessWidget {
  final int index;
  final double value;
  final String targetedWeight;
  final int? activityLevel;
  final List<String> healthConcerentList;
  final String? activityLevelText;

  const BmiContainer({
    super.key,
    required this.index,
    required this.value,
    required this.targetedWeight,
    required this.activityLevel,
    required this.healthConcerentList,
    this.activityLevelText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: cardBorder,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadow,
      ),
      padding: EdgeInsets.only(left: 12, right: 12, top: 13.5, bottom: 17.5),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 1,
                child: CustomText(
                  text: 'Body Mass Index (BMI) $value',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff851653),
                  textAlign: TextAlign.center,
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: index == 0
                          ? 85
                          : index == 1
                          ? 120
                          : index == 2
                          ? 112
                          : 80,
                      height: 24,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Color(0xffFDF2FA)
                            : index == 1
                            ? Color(0xff2D9CDB)
                            : index == 2
                            ? Color(0xffF2C94C)
                            : Color(0xffEB5757),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: index == 0
                              ? Color(0xffFCE7F6)
                              : index == 1
                              ? Color(0xff2D9CDB)
                              : index == 2
                              ? Color(0xffF2C94C)
                              : Color(0xffEB5757),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/star.png',
                              height: 12,
                              width: 11.91,
                              color: index == 0
                                  ? Color(0xffEF45B2)
                                  : Colors.white,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                            SizedBox(width: 4),
                            CustomText(
                              text: index == 0
                                  ? 'NORMAL'
                                  : index == 1
                                  ? 'UNDERWEIGHT'
                                  : index == 2
                                  ? 'OVERWEIGHT'
                                  : 'OBESE',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: index == 0
                                  ? Color(0xffEF45B2)
                                  : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 9),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                fontSize: 13.2,
                color: Color(0xff4D5761),
              ),
              children: [
                const TextSpan(
                  text: 'High BMI leads to greater health risks. ',
                ),
                TextSpan(
                  text: 'Reference Link',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => openWebLink(
                      url: bmiReferenceUrl,
                      title: 'BMI Reference',
                    ),
                  style: GoogleFonts.roboto(
                    color: const Color(0xff851653),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),

          BmiRangeBar(bmiValue: value),
          SizedBox(height: 8),
          Image.asset('assets/images/Divider.png', width: double.infinity),
          SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/icons/weight_device.png',
                            height: 24,
                            fit: BoxFit.cover,
                            width: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Target Weight',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff6C737F),
                                ),
                                CustomText(
                                  text: targetedWeight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff384250),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/icons/Vector(1).png',
                            height: 19,
                            fit: BoxFit.cover,
                            width: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Illness attention',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff6C737F),
                                ),
                                CustomText(
                                  text: healthConcerentList.join(", "),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff384250),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/icons/Group.png',
                            height: 24,
                            width: 24,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Level',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff6C737F),
                                ),
                                CustomText(
                                  text: activityLevel == null
                                      ? activityLevelText ?? ''
                                      : activityLevel == 0
                                      ? 'Sedentary'
                                      : activityLevel == 1
                                      ? 'Lightly Activity'
                                      : activityLevel == 2
                                      ? 'Moderately Activity'
                                      : 'Very Active',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff384250),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                Flexible(
                  flex: 0,
                  child: Image.asset(
                    'assets/images/yoga_girl.png',
                    width: 120,
                    height: 87,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
