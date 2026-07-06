import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class BmiRangeBar extends StatelessWidget {
  final double bmiValue;

  const BmiRangeBar({super.key, required this.bmiValue});

  @override
  Widget build(BuildContext context) {
    const double min = 15;
    const double max = 40;

    double percent = ((bmiValue - min) / (max - min)).clamp(0, 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double actualBarWidth = constraints.maxWidth - 12;

        final double indicatorX =
            9 + (percent * actualBarWidth).clamp(0, actualBarWidth);

        return Column(
          children: [
            SizedBox(
              height: 35,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: 0,
                    left: 9,
                    right: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: actualBarWidth,
                        height: 8,
                        child: Row(
                          children: [
                            _bar(16.7 - 15, const Color(0xff9B51E0)),
                            _bar(18.5 - 16.7, const Color(0xff56CCF2)),
                            _bar(25 - 18.5, const Color(0xff27AE60)),
                            _bar(30 - 25, const Color(0xffF2C94C)),
                            _bar(35 - 30, const Color(0xffF2994A)),
                            _bar(40 - 35, const Color(0xffEB5757)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: indicatorX - 12,
                    bottom: 10,
                    child: Image.asset(
                      'assets/images/indecator.png',
                      width: 20,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                _Label("15     "),
                _Label("16"),
                SizedBox(width: 15),
                _Label("18.5      "),
                Spacer(),
                _Label("25"),
                Spacer(),
                _Label("30"),
                Spacer(),
                _Label("35"),
                Spacer(),
                _Label("40"),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _bar(double flex, Color color) {
    return Expanded(
      flex: (flex * 100).toInt(),
      child: Container(color: color),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return CustomText(
      text: text,
      fontWeight: FontWeight.w400,
      fontSize: 8,
      color: Color(0xff9DA4AE),
    );
  }
}
