import 'package:docwellness/app/modules/auth/widgets/bmi_range_bar.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final int intake;
  final int remaining;
  final int exercise;
  final int totalPlanned;
  final int carbsConsumed;
  final int carbsPlanned;
  final int proteinConsumed;
  final int proteinPlanned;
  final int fiberConsumed;
  final int fiberPlanned;
  final int fatConsumed;
  final int fatPlanned;
  final int cheatCalories;
  final bool hasData;
  // false when the Home screen merges this into one card together with the
  // water intake section (see home_view.dart) - the outer border/shadow/
  // background then belongs to that shared container instead of this one,
  // so this card doesn't paint a second nested border around itself.
  final bool standalone;

  // BMI info for empty state
  final double bmiValue;
  final int bmiIndex;
  final String targetWeight;
  final String activityLevel;
  final List<String> healthConcerns;

  const ProgressCard({
    super.key,
    this.intake = 0,
    this.remaining = 0,
    this.exercise = 0,
    this.totalPlanned = 0,
    this.carbsConsumed = 0,
    this.carbsPlanned = 0,
    this.proteinConsumed = 0,
    this.proteinPlanned = 0,
    this.fiberConsumed = 0,
    this.fiberPlanned = 0,
    this.fatConsumed = 0,
    this.fatPlanned = 0,
    this.cheatCalories = 0,
    this.hasData = false,
    this.standalone = true,
    this.bmiValue = 0.0,
    this.bmiIndex = 0,
    this.targetWeight = '',
    this.activityLevel = '',
    this.healthConcerns = const [],
  });

  double _safeProgress(int consumed, int planned) {
    if (planned <= 0) return 0;
    return (consumed / planned).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (!standalone) return body;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: cardBorder,
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadow,
      ),
      child: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final double calorieProgress = totalPlanned > 0
        ? (intake / totalPlanned).clamp(0.0, 1.0)
        : 0.0;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ---------- HEADER ----------
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xffFCCEEF),
                  borderRadius: BorderRadius.circular(64),
                ),
                child: Center(
                  child: Icon(
                    Icons.trending_up,
                    color: Color(0xff9F1561),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Your progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff530630),
                ),
              ),
              const Spacer(),
              if (hasData) ...[
                Icon(Icons.shield_outlined, size: 16, color: Color(0xffA0A6B0)),
                const SizedBox(width: 6),
                Text(
                  "Cheat Calories: $cheatCalories",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff9DA4AE),
                  ),
                ),
              ],
            ],
          ),

          if (!hasData) ...[
            const SizedBox(height: 16),
            // BMI Info Section
            if (bmiValue > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: CustomText(
                      text:
                          'Body Mass Index (BMI) ${bmiValue.toStringAsFixed(1)}',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xff851653),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    height: 24,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: bmiIndex == 0
                          ? Color(0xffFDF2FA)
                          : bmiIndex == 1
                          ? Color(0xff2D9CDB)
                          : bmiIndex == 2
                          ? Color(0xffF2C94C)
                          : Color(0xffEB5757),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomText(
                        text: bmiIndex == 0
                            ? 'NORMAL'
                            : bmiIndex == 1
                            ? 'UNDERWEIGHT'
                            : bmiIndex == 2
                            ? 'OVERWEIGHT'
                            : 'OBESE',
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: bmiIndex == 0 ? Color(0xffEF45B2) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              BmiRangeBar(bmiValue: bmiValue),
              SizedBox(height: 12),
              Divider(color: Color(0xffFCE7F6), thickness: 1),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (targetWeight.isNotEmpty) ...[
                          _infoRow(
                            icon: 'assets/icons/weight_device.png',
                            label: 'Target Weight',
                            value: targetWeight,
                          ),
                          SizedBox(height: 8),
                        ],
                        if (healthConcerns.isNotEmpty) ...[
                          _infoRow(
                            icon: 'assets/icons/Vector(1).png',
                            label: 'Illness attention',
                            value: healthConcerns.join(', '),
                          ),
                          SizedBox(height: 8),
                        ],
                        if (activityLevel.isNotEmpty)
                          _infoRow(
                            icon: 'assets/icons/Group.png',
                            label: 'Activity Level',
                            value: activityLevel,
                          ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/yoga_girl.png',
                    width: 100,
                    height: 75,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 48,
                      color: Color(0xffFCCEEF),
                    ),
                    const SizedBox(height: 12),
                    CustomText(
                      text: "No progress data yet",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff9DA4AE),
                    ),
                    const SizedBox(height: 6),
                    CustomText(
                      text:
                          "Start logging your meals to track\nyour daily progress",
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff9DA4AE),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 32),

            /// ---------- MIDDLE SECTION (CALORIES + CIRCLE) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// LEFT INTAKE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomText(
                        text: "Intake",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff530630),
                      ),
                      CustomText(
                        text: "$intake",
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff530630),
                      ),
                    ],
                  ),

                  _CircularProgress(
                    value: calorieProgress,
                    calories: remaining,
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomText(
                        text: "Exercise",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff530630),
                      ),
                      CustomText(
                        text: "$exercise",
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff530630),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomHorizontalIndicator(
                      subTitle: '$carbsConsumed/${carbsPlanned}g',
                      title: "Net Carbs",
                      progress: _safeProgress(carbsConsumed, carbsPlanned),
                    ),
                  ),
                  SizedBox(width: 58),
                  Expanded(
                    child: CustomHorizontalIndicator(
                      subTitle: '$proteinConsumed/${proteinPlanned}g',
                      title: "Protein",
                      progress: _safeProgress(proteinConsumed, proteinPlanned),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomHorizontalIndicator(
                      subTitle: '$fiberConsumed/${fiberPlanned}g',
                      title: "Fiber",
                      progress: _safeProgress(fiberConsumed, fiberPlanned),
                    ),
                  ),
                  SizedBox(width: 58),
                  Expanded(
                    child: CustomHorizontalIndicator(
                      subTitle: '$fatConsumed/${fatPlanned}g',
                      title: "Fat",
                      progress: _safeProgress(fatConsumed, fatPlanned),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
  }

  Widget _infoRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(icon, height: 20, width: 20, fit: BoxFit.cover),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: label,
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xff6C737F),
              ),
              CustomText(
                text: value,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xff384250),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------- CIRCULAR PROGRESS WIDGET ----------
class _CircularProgress extends StatelessWidget {
  final double value;
  final int calories;

  const _CircularProgress({required this.value, required this.calories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120, 120),
            painter: _FullCirclePainter(
              progress: value,
              backgroundColor: const Color(0xffFCE7F6),
              progressColor: const Color(0xffDE2493),
              strokeWidth: 16,
            ),
          ),

          /// Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: "$calories",
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xff530630),
              ),
              CustomText(
                text: "can eat",
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xff530630),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ------------------ FULL 360° ROUND CIRCLE ------------------

class _FullCirclePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _FullCirclePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    /// Background ring (full circle)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // <-- Rounded edges

    canvas.drawArc(rect, 0, 2 * 3.1415926535, false, bgPaint);

    /// Progress ring (full circle based on progress)
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -3.14 / 2,
      (2 * 3.1415926535) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CustomHorizontalIndicator extends StatelessWidget {
  final double progress;
  final String title;
  final String subTitle;

  const CustomHorizontalIndicator({
    super.key,
    required this.progress,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: title,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Color(0xff530630),
        ),
        const SizedBox(height: 8),

        // --- PROGRESS BAR ---
        Row(
          children: [
            // Dark side (progress)
            Expanded(
              flex: (progress * 100).toInt(),
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xff530630),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Light side (remaining)
            Expanded(
              flex: ((1 - progress) * 100).toInt(),
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xffFCCEEF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        CustomText(
          text: subTitle,
          fontWeight: FontWeight.w400,
          fontSize: 10,
          color: Color(0xff9DA4AE),
        ),
      ],
    );
  }
}
