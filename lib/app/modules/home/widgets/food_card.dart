import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final String image;
  final String name;
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
  // Optional action shown to the right of the recipe name (e.g. the Diet
  // Plan timeline's per-recipe Quick Log button). Laid out as a real
  // sibling of the title - the name Expands and ellipsizes beside it -
  // rather than floated on top, so it can never overlap the text.
  final Widget? trailing;
  const FoodCard({
    super.key,
    required this.onTap,
    required this.image,
    required this.name,
    required this.calorie,
    required this.protein,
    required this.fiber,
    required this.carbs,
    required this.fat,
    this.supplementNutrientLabels,
    this.trailing,
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
                            image: CachedNetworkImageProvider(image),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomText(
                              text: name,
                              color: const Color(0xff384250),
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              height: 1.2,
                            ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: 8),
                            trailing!,
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // The quantity/tbsp-conversion pill row that used to
                      // sit here was removed for a cleaner card - that
                      // detail now lives on the Recipe Details screen's
                      // Ingredients tab instead (see recipe_details_screen
                      // .dart/ingredient_tab.dart), where there's room to
                      // show it per-ingredient rather than crowding this
                      // compact timeline card.
                      if (!_isSupplement)
                        CustomText(
                          text: "$calorie calorie",
                          fontWeight: FontWeight.w400,
                          color: Color(0xff6C737F),
                          fontSize: 12,
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
