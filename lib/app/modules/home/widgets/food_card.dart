import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/functions/quantity_label.dart';
import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final String image;
  final String name;
  // Raw quantity only (e.g. "100", not "100G") - the badge below applies
  // the same tbsp/cup approximation the dietician app shows (see
  // quantity_label.dart), so `unit` must be passed separately.
  final String gram;
  final String unit;
  final String calorie;
  final String protein;
  final String fiber;
  final String carbs;
  final String fat;
  final VoidCallback onTap;
  // Pre-formatted "name amount unit · x% NRV" labels (see
  // SupplementNutrient.displayLabel) for a supplement recipe - when
  // non-null and non-empty, these replace the calorie text and the
  // Protein/Fiber/Carbs/Fat row below, since those macro numbers are
  // meaningless (zeroed) for a vitamin/mineral tablet. Mirrors the
  // dietician app's identical FoodCard behavior.
  final List<String>? supplementNutrientLabels;
  const FoodCard({
    super.key,
    required this.onTap,
    required this.image,
    required this.name,
    required this.gram,
    this.unit = '',
    required this.calorie,
    required this.protein,
    required this.fiber,
    required this.carbs,
    required this.fat,
    this.supplementNutrientLabels,
  });

  bool get _isSupplement =>
      supplementNutrientLabels != null && supplementNutrientLabels!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF6FB),
                    image: image.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(image),
                            fit: BoxFit.cover,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: name,

                        color: Color(0xff384250),
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xffEF45B2)),
                              color: const Color(0xffFCE7F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomText(
                              text: formatQuantityLabel(gram, unit),

                              color: Color(0xff851653),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          if (!_isSupplement) ...[
                            const SizedBox(width: 5),
                            CustomText(
                              text: "$calorie calorie",

                              fontWeight: FontWeight.w400,
                              color: Color(0xff6C737F),
                              fontSize: 12,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // A supplement shows its real active-ingredient facts
            // (horizontally scrollable, since e.g. a multivitamin can list
            // 20+ nutrients) instead of the macro pills, which are
            // meaningless (zeroed) for it.
            if (_isSupplement)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final label in supplementNutrientLabels!)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFDF2FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomText(
                          text: label,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: const Color(0xff851653),
                        ),
                      ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FoodInfoIndicator(
                    value: "${protein}g",
                    label: "Protein",
                    icon: 'assets/icons/diet1.png',
                  ),
                  FoodInfoIndicator(
                    value: "${fiber}g",
                    label: "Fiber",
                    icon: 'assets/icons/diet2.png',
                  ),
                  FoodInfoIndicator(
                    value: "${carbs}g",
                    label: "Carbs",
                    icon: 'assets/icons/diet3.png',
                  ),
                  FoodInfoIndicator(
                    value: "${fat}g",
                    label: "Fat",
                    icon: 'assets/icons/diet4.png',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class FoodInfoIndicator extends StatelessWidget {
  final String value;
  final String label;
  final String icon;

  const FoodInfoIndicator({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Vertical progress bar
        Image.asset(icon, height: 24, width: 24),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: value,

              color: Color(0xff384250),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            CustomText(
              text: label,

              color: Color(0xff6C737F),
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ],
        ),
      ],
    );
  }
}
