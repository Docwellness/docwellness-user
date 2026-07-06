import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class WeightBmiContainer extends StatelessWidget {
  final int index;
  final double bmi;
  const WeightBmiContainer({super.key, required this.index, required this.bmi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 8, bottom: 12, right: 13, left: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xffF9FAFB)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x08000000),
            offset: const Offset(0, 5),
            blurRadius: 25,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0x1B000000),
            offset: const Offset(0, 1.14),
            blurRadius: 5.72,
            spreadRadius: -2.67,
          ),
          BoxShadow(
            color: const Color(0x1F000000),
            offset: const Offset(0, 0.3),
            blurRadius: 1.51,
            spreadRadius: -1.33,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                text: 'Your BMI: $bmi',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0xff851653),
              ),
              SizedBox(width: 12),
              Container(
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
                        color: index == 0 ? Color(0xffEF45B2) : Colors.white,
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
                        color: index == 0 ? Color(0xffEF45B2) : Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          CustomText(
            text: index == 0
                ? 'You’ve got a great figure! Keep it up! We’ll use your index to tailor personal programs to your needs'
                : index == 1
                ? 'You have great potential to get in better shape! Move on now!'
                : index == 2
                ? 'You should pay more attention to your weight. We will use your index to tailor a personal plan for weight loss'
                : 'Your BMI indicates obesity, which increases health risks. We will create a personalized plan to help you achieve a healthier weight.',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Color(0xff4D5761),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Center(
            child: InkWell(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: 'Source of recommendations',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xff9DA4AE),
                    textAlign: TextAlign.center,
                  ),

                  Container(
                    height: 1,
                    width: 155,
                    color: Color(0xff9DA4AE).withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
