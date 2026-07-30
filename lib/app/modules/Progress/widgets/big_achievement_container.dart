import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class BigAchievementContainer extends StatelessWidget {
  final String title;
  final String description;
  final String icon;

  const BigAchievementContainer({
    super.key,
    required this.title,
    required this.description,
    this.icon = 'badge',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 117,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xffFEF6FB),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Image.asset('assets/images/badge.png', height: 94),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 19),
                  CustomText(
                    text: title,
                    color: Color(0xffDE2493),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 2),
                  CustomText(
                    text: description,
                    color: Color(0xff530630),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
