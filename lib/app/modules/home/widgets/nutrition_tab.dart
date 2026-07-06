import 'dart:math';

import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class NutritionDetailsWidget extends StatefulWidget {
  const NutritionDetailsWidget({super.key});

  @override
  State<NutritionDetailsWidget> createState() => _NutritionDetailsWidgetState();
}

class _NutritionDetailsWidgetState extends State<NutritionDetailsWidget> {
  bool isVisibil = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        Container(
          padding: EdgeInsets.only(top: 16, left: 19, bottom: 8, right: 19),
          decoration: BoxDecoration(
            color: Color(0xffFEF6FB).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 23,
            runSpacing: 20,
            children: const [
              NutritionCircle(title: "Protein", grams: 50, percent: 0.25),
              NutritionCircle(title: "Fat", grams: 50, percent: 0.25),
              NutritionCircle(title: "Carbs", grams: 50, percent: 0.25),
              NutritionCircle(title: "Fiber", grams: 50, percent: 0.25),
            ],
          ),
        ),
        SizedBox(height: 16),
        //---------------- SERVING SIZE BAR ----------------
        GestureDetector(
          onTap: () {
            setState(() {
              isVisibil = !isVisibil;
            });
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xff851653),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: "Per Serving",
                    color: Color(0xffFCFCFD),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  Icon(
                    isVisibil == false
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Color(0xffFCFCFD),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        //---------------- CALORIES BLOCK ----------------
        Visibility(
          visible: isVisibil,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pinkContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: "Calories",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff111927),
                    ),
                    CustomText(
                      text: "110 kcal",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff111927),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              //---------------- TOTAL FAT ----------------
              nutritionItem(
                title: "Total fat",
                value: "0.5g",
                dv: "1%",
                sub: const [
                  _SubNutrition(title: "Saturated fat", value: "0g", dv: "1%"),
                  _SubNutrition(title: "Trans fat", value: "0g", dv: "1%"),
                ],
              ),

              nutritionItem(title: "Protein", value: "0mg", dv: "1%"),

              nutritionItem(
                title: "Total Carbohydrates",
                value: "0.5g",
                dv: "1%",
                sub: const [
                  _SubNutrition(title: "Dietary Fiber", value: "0g", dv: "1%"),
                  _SubNutrition(title: "Sugar", value: "0g", dv: "1%"),
                ],
              ),

              nutritionItem(title: "Cholesterol", value: "0mg", dv: "1%"),
              nutritionItem(title: "Sodium", value: "0mg", dv: "1%"),
              nutritionItem(title: "Calcium", value: "0mg", dv: "1%"),
              nutritionItem(title: "Iron", value: "0mg", dv: "1%"),
              nutritionItem(title: "Potassium", value: "0mg", dv: "1%"),
              nutritionItem(title: "Vitamin C", value: "0mg", dv: "1%"),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

//
// PINK SECTION CONTAINER
//
Widget pinkContainer({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xffFEF6FB),
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

//
// MAIN NUTRITION ITEM
//
Widget nutritionItem({
  required String title,
  required String value,
  required String dv,
  List<_SubNutrition>? sub,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: pinkContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: nutritionRow(title, value, dv, bold: true),
          ),
          if (sub != null)
            ...sub.map((e) => nutritionRow("   ${e.title}", e.value, e.dv)),
        ],
      ),
    ),
  );
}

//
// SINGLE ROW
//
Widget nutritionRow(
  String title,
  String value,
  String dv, {
  bool bold = false,
}) {
  return Row(
    children: [
      Expanded(
        child: CustomText(
          text: title,
          fontSize: 14,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: const Color(0xff384250),
        ),
      ),
      CustomText(
        text: value,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xff384250),
      ),
      const SizedBox(width: 12),
      CustomText(
        text: dv,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xff384250),
      ),
    ],
  );
}

//
// MODEL
//
class _SubNutrition {
  final String title;
  final String value;
  final String dv;

  const _SubNutrition({
    required this.title,
    required this.value,
    required this.dv,
  });
}

class NutritionCircle extends StatelessWidget {
  final String title;
  final double grams;
  final double percent;

  const NutritionCircle({
    super.key,
    required this.title,
    required this.grams,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 54,
          width: 54,
          child: CustomPaint(
            painter: _CirclePainter(percent),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${grams.toInt()}g",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff530630),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "${(percent * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w300,
                      color: Color(0xff530630),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: Color(0xff530630),
          ),
        ),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double percent;
  _CirclePainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = const Color(0xffFCE7F6)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xffDE2493)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Full background circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      backgroundPaint,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percent,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
