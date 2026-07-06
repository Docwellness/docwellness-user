import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class CalorieIntake extends StatelessWidget {
  final String title;
  final String description;

  const CalorieIntake({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 101,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 10),
        child: Row(
          children: [
            Image.asset('assets/images/row.png', height: 94),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 19),
                  CustomText(
                    text: title,
                    color: Color(0xff334155),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 2),
                  CustomText(
                    text: description,
                    color: Color(0xff334155),
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
