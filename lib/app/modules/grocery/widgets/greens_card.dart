import 'package:docwellness/app/modules/grocery/models/grocery_model.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class GroceryTile extends StatefulWidget {
  final GroceryItem item;
  final VoidCallback? onTogglePurchased;

  const GroceryTile({super.key, required this.item, this.onTogglePurchased});

  @override
  State<GroceryTile> createState() => _GroceryTileState();
}

class _GroceryTileState extends State<GroceryTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPurchased = item.purchased;

    // Prefer the backend's pre-formatted friendly string (e.g. "330g (~3
    // medium onion)") now that totalQuantity/unit are always the base unit
    // (grams/ml) - fall back to the raw number for anything without a
    // natural friendly conversion (e.g. a supplement, or an ingredient with
    // no piece/cup equivalent).
    final qty = item.totalQuantity == item.totalQuantity.truncateToDouble()
        ? item.totalQuantity.toInt().toString()
        : item.totalQuantity.toStringAsFixed(1);
    final qtyLabel =
        item.displayQuantity ??
        (item.unit != null ? '$qty ${item.unit}' : qty);

    // Subtitle: category + priceLevel
    final subtitle = [
      if (item.category != null) item.category!,
      if (item.priceLevel != null) item.priceLevel!,
    ].join(' • ');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 12,
            left: 13,
            right: 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () {
                  widget.onTogglePurchased?.call();
                  setState(() {});
                },
                child: Image.asset(
                  isPurchased
                      ? 'assets/icons/Checkboxes(1).png'
                      : 'assets/icons/Checkboxes.png',
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 15),

              // Ingredient image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.image != null
                    ? Image.network(
                        item.image!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackImage(),
                      )
                    : _fallbackImage(),
              ),

              const SizedBox(width: 21),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.name,
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: const Color(0xff1F2A37),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (subtitle.isNotEmpty)
                          CustomText(
                            text: subtitle,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: const Color(0xff6C737F),
                          ),
                        Row(
                          children: [
                            CustomText(
                              text: qtyLabel,
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                              color: const Color(0xff1F2A37),
                            ),
                            if (item.recipesUsedIn.isNotEmpty) ...[
                              const SizedBox(width: 21.5),
                              InkWell(
                                onTap: () =>
                                    setState(() => isExpanded = !isExpanded),
                                child: Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 24,
                                  color: const Color(0xff0D121C),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Badge
                    _badge(isPurchased),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 1,
            color: isExpanded
                ? const Color(0xffD2D6DB)
                : const Color(0xffFCCEEF),
          ),
        ),

        // Expanded: recipes that use this ingredient
        if (isExpanded && item.recipesUsedIn.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 54),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < item.recipesUsedIn.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        _recipeTile(item.recipesUsedIn[i]),
                      ],
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 1,
                  color: const Color(0xffFCCEEF),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _badge(bool isPurchased) {
    if (isPurchased) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffF3F4F6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/correct.png', width: 12, height: 12),
            const SizedBox(width: 4),
            const CustomText(
              text: 'ALREADY PURCHASED',
              color: Color(0xff6C737F),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      );
    }

    // "DIETICIAN VERIFIED" badge removed for now (product decision) - not
    // meaningful for a grocery ingredient line item.
    return const SizedBox.shrink();
  }

  Widget _recipeTile(RecipeUsedIn recipe) {
    // Each entry carries its OWN original unit (e.g. "tbsp") - a single
    // canonical ingredient can legitimately mix units across the recipes it
    // appears in, so this must not fall back to the parent item's aggregate
    // base unit (which would mislabel e.g. "2 tbsp" as "2 g").
    final qty = recipe.quantity == recipe.quantity.truncateToDouble()
        ? recipe.quantity.toInt().toString()
        : recipe.quantity.toStringAsFixed(1);
    final qtyLabel = recipe.unit != null ? '$qty ${recipe.unit}' : qty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: recipe.recipeImage != null
              ? Image.network(
                  recipe.recipeImage!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackImage(size: 48),
                )
              : _fallbackImage(size: 48),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomText(
            text: recipe.recipeName,
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: const Color(0xff1F2A37),
          ),
        ),
        const SizedBox(width: 8),
        CustomText(
          text: qtyLabel,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: const Color(0xff6C737F),
        ),
        const SizedBox(width: 50),
      ],
    );
  }

  Widget _fallbackImage({double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.fastfood_outlined, color: Color(0xff9CA3AF)),
    );
  }
}
