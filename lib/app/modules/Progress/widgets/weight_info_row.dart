import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class WeightInfoRow extends StatelessWidget {
  final double currentWeight;
  final double targetWeight;
  final double initialWeight;
  final double percentageChange;
  final double progress;

  const WeightInfoRow({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.initialWeight,
    required this.percentageChange,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double baseWidth = constraints.maxWidth;

        double labelSize = baseWidth * 0.035;
        double numberSize = baseWidth * 0.055;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// CURRENT WEIGHT
            _weightTile(
              title: "Current weight",
              value: currentWeight > 0 ? currentWeight.toInt().toString() : "--",
              numberColor: Color(0xff851653),
              numberSize: numberSize,
              labelSize: labelSize,
              child: percentageChange > 0
                  ? Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xffFCE7F6)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: labelSize + 4,
                      color: Color(0xff851653),
                    ),
                    CustomText(
                      text: "${percentageChange.toInt()}%",

                      fontSize: labelSize - 1,
                      color: Color(0xff851653),
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              )
                  : null,
            ),

            /// TARGET WEIGHT
            _weightTile(
              title: "Target weight",
              value: targetWeight > 0 ? targetWeight.toInt().toString() : "--",
              numberColor: Color(0xff111927),
              numberSize: numberSize,
              labelSize: labelSize,
            ),

            /// INITIAL WEIGHT (with progress circle)
            _weightTile(
              title: "Initial weight",
              value: initialWeight > 0 ? initialWeight.toInt().toString() : "--",
              numberColor: Color(0xff4D5761),
              numberSize: numberSize,
              labelSize: labelSize,
            ),
          ],
        );
      },
    );
  }

  /// REUSABLE TILE
  Widget _weightTile({
    required String title,
    required String value,
    required Color numberColor,
    required double numberSize,
    required double labelSize,
    Widget? child,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: title,

            fontSize: labelSize,
            color: title == 'Initial weight'
                ? Color(0xffD2D6DB)
                : Color(0xff4D5761),
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: 4),
          Row(
            children: [
              CustomText(
                text: value,

                fontSize: numberSize,
                color: numberColor,
                fontWeight: FontWeight.w600,
              ),

              if (child != null) SizedBox(width: 6),
              if (child != null) child,
            ],
          ),
        ],
      ),
    );
  }
}
