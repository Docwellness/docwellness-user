import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/app/modules/home/widgets/cooking_steps_tab.dart';
import 'package:docwellness/app/modules/home/widgets/ingredient_tab.dart';
import 'package:docwellness/app/modules/home/widgets/nutrition_tab.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final ScrollController scrollController;
  final Recipe recipe;
  const RecipeDetailsScreen({
    super.key,
    required this.scrollController,
    required this.recipe,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  int selectedTab = 0;
  int counter = 1;
  String _selectedLanguage = 'English';

  /// Formats an ingredient quantity for display without floating-point
  /// artifacts (e.g. 0.30000000000000004) - whole numbers show with no
  /// decimals, fractional values show with up to 2 decimals, trailing
  /// zeros trimmed.
  String _formatQuantity(num quantity) {
    final q = quantity.toDouble();
    if (q == q.roundToDouble()) return q.toStringAsFixed(0);
    var s = q.toStringAsFixed(2);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  String get recipeName {
    if (_selectedLanguage != 'English') {
      final t = widget.recipe.translations[_selectedLanguage];
      if (t != null && t.name.isNotEmpty) return t.name;
    }
    return widget.recipe.name;
  }

  List<String> get instructions {
    if (_selectedLanguage != 'English') {
      final t = widget.recipe.translations[_selectedLanguage];
      if (t != null && t.cookingSteps.isNotEmpty) return t.cookingSteps;
    }
    return widget.recipe.instructions;
  }

  String ingredientName(int index) {
    if (_selectedLanguage != 'English') {
      final t = widget.recipe.translations[_selectedLanguage];
      if (t != null && index < t.ingredients.length) {
        final translated = t.ingredients[index].name;
        if (translated.isNotEmpty) return translated;
      }
    }
    return widget.recipe.ingredients[index].name;
  }

  // A supplement's real active-ingredient facts replace the ordinary
  // macro/DV nutrition view (meaningless for a vitamin/mineral tablet) and
  // its "Cooking steps" tab is really consumption/dosage guidance, not a
  // recipe method.
  bool get _isSupplement =>
      widget.recipe.supplementFacts != null &&
      widget.recipe.supplementFacts!.nutrients.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // top placeholder image
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10, top: 10),
            decoration: BoxDecoration(
              color: Color(0xff79747E),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        Container(
          height: 196,
          width: double.infinity,

          decoration: BoxDecoration(
            color: const Color(0xffFEF6FB),
            image: widget.recipe.image.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(widget.recipe.image),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),

        Padding(
          padding: EdgeInsets.only(left: 16, top: 8, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: recipeName,

                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff384250),
                    ),

                    CustomText(
                      text:
                          "Vitamin rich • ${widget.recipe.nutrition.calories.round()} calories",

                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff6C737F),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 5),
              Container(
                height: 24,
                width: 144,
                decoration: BoxDecoration(
                  color: const Color(0xffFDF2FA),
                  border: Border.all(color: Color(0xffFCE7F6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/Icon.png',
                        height: 12,
                        width: 12,
                      ),
                      SizedBox(width: 6),
                      CustomText(
                        text: "DIETICIAN VERIFIED",

                        color: Color(0xFFEF45B2),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ------------------- LANGUAGE SELECTOR -------------------
        if (widget.recipe.languages.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: widget.recipe.languages.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLanguage = lang;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xff530630)
                            : const Color(0xffFDF2FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff530630)
                              : const Color(0xffFCE7F6),
                        ),
                      ),
                      child: CustomText(
                        text: lang,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xff530630),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // ------------------- CUSTOM SEGMENTED TAB BAR -------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Color(0xff530630), width: 1),
            ),
            child: Row(
              children: [
                _buildTab(0, "Ingredients"),
                _verticalDivider(),
                _buildTab(1, "Nutrition value"),
                _verticalDivider(),
                _buildTab(2, _isSupplement ? "Dosage" : "Cooking steps"),
              ],
            ),
          ),
        ),

        SizedBox(height: selectedTab == 0 ? 9 : 16),

        Expanded(
          child: IndexedStack(
            index: selectedTab,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    if (selectedTab == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: Container(
                          padding: EdgeInsets.only(
                            right: 27,
                            left: 24,
                            top: 21,
                            bottom: 21,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xffFEF6FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/ion_warning-outline.png',
                                height: 30,
                                width: 30,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: CustomText(
                                  text:
                                      'Contains: Soy, Nuts. Not suitable for gluten-free diets.',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Color(0xff851653),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (selectedTab == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              text: 'Servings',
                              fontWeight: FontWeight.w500,
                              fontSize: 22,
                              color: Color(0xff384250),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (counter > 1) {
                                        counter--;
                                      }
                                    });
                                  },

                                  child: Image.asset(
                                    'assets/icons/Minus.png',
                                    height: 30,
                                    width: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 15),
                                CustomText(
                                  text: counter.toString(),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: Color(0xffC11576),
                                ),
                                SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      counter++;
                                    });
                                  },
                                  child: Image.asset(
                                    'assets/icons/Plus.png',
                                    height: 30,
                                    width: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(thickness: 0.7, color: Color(0xffFCCEEF)),
                    ),
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: widget.recipe.ingredients.length,
                      itemBuilder: (context, index) {
                        final data = widget.recipe.ingredients[index];
                        return IngredientTile(
                          image: data.image,
                          name: ingredientName(index),
                          gram:
                              '${_formatQuantity(data.quantity)}${data.unit.toLowerCase()}',
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: CustomText(
                        text:
                            'If you identify any kind allergies with ingredients, we kindly request you, not to proceed any further with this recipe. Contact us or your family doctor for consultation.',
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        color: Color(0xff6C737F),
                      ),
                    ),
                  ],
                ),
              ),
              NutritionDetailsWidget(
                nutrition: widget.recipe.nutrition,
                supplementFacts: widget.recipe.supplementFacts,
              ),
              CookingStepsTab(
                recipe: widget.recipe,
                translatedSteps: _selectedLanguage != 'English'
                    ? instructions
                    : null,
                isSupplement: _isSupplement,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- TAB ITEM ----------------
  Widget _buildTab(int index, String title) {
    final bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? Color(0xffFDF2FA) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(index == 0 ? 22 : 0),
              bottomLeft: Radius.circular(index == 0 ? 22 : 0),
              topRight: Radius.circular(index == 2 ? 22 : 0),
              bottomRight: Radius.circular(index == 2 ? 22 : 0),
            ),
          ),
          alignment: Alignment.center,
          child: CustomText(
            fontSize: 13,
            text: title,

            color: isSelected ? Color(0xff530630) : Color(0xff384250),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------- DIVIDER ----------------
  Widget _verticalDivider() {
    return Container(
      width: 1.3,
      height: double.infinity,
      color: Color(0xff530630),
    );
  }
}
