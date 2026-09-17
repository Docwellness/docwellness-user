import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/app/modules/home/widgets/cooking_steps_tab.dart';
import 'package:docwellness/app/modules/home/widgets/ingredient_tab.dart';
import 'package:docwellness/app/modules/home/widgets/nutrition_tab.dart';
import 'package:docwellness/app/services/recipe_language_service.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
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
  String? _pressedLang;

  @override
  void initState() {
    super.initState();
    // Default to the patient's Recipe Language preference (Settings) - but
    // only if this particular recipe actually has content in it; the pill
    // selector below only ever offers widget.recipe.languages, so seeding
    // a language this recipe doesn't support would silently fall back to
    // English content anyway while showing no selector to explain why.
    final preferred = RecipeLanguageService.instance.current.value;
    if (widget.recipe.languages.contains(preferred)) {
      _selectedLanguage = preferred;
    }
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _titleBarOpacity.dispose();
    super.dispose();
  }

  // Fades the pinned title bar in once the user has scrolled past the
  // header image, so there's still a way to tell which recipe this is once
  // the big header scrolls out of view. The threshold (drag handle + image)
  // is a real, fixed layout constant - not a guess about how tall the
  // title/description text will end up being, so unlike the old
  // _headerExpandedHeight this can't drift out of sync with content and
  // doesn't force the header into a fixed-size box to compute it. A plain
  // opacity overlay outside the sliver list (see build()) rather than a
  // pinned SliverPersistentHeader, so it never reserves its own 56px of
  // permanent blank space in the scroll content.
  static const double _titleBarFadeDistance =
      220; // drag handle(24) + image(196)
  final ValueNotifier<double> _titleBarOpacity = ValueNotifier(0);

  void _onScroll() {
    _titleBarOpacity.value =
        (widget.scrollController.offset / _titleBarFadeDistance).clamp(
          0.0,
          1.0,
        );
  }

  // PORTIONS SUMMARY (component chips) + LANGUAGE SELECTOR, as their own
  // elevated sheet directly below the header image - curved top corners and
  // a tinted background matching the ingredient-tab card's own 0xffFEF6FB
  // (see the Ingredients tab below) so it reads as part of this recipe's
  // UI language, not a generic panel. Sized entirely by its own content:
  // unlike the header above it, nothing here needs a height guess.
  Widget _buildPortionsAndLanguageCard() {
    final hasComponents = widget.recipe.components.isNotEmpty;
    final hasLanguages = widget.recipe.languages.length > 1;
    if (!hasComponents && !hasLanguages) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasComponents)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < widget.recipe.components.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFCE7F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomText(
                      text: widget.recipe.components.length > 1
                          ? '${_componentLabel(i, widget.recipe.components[i].label)}: ${_formatQuantity(widget.recipe.components[i].quantity)} ${widget.recipe.components[i].unit}'
                          : '${_formatQuantity(widget.recipe.components[i].quantity)} ${widget.recipe.components[i].unit}',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: const Color(0xff851653),
                    ),
                  ),
              ],
            ),
          if (hasComponents && hasLanguages) const SizedBox(height: 12),
          if (hasLanguages)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.recipe.languages.map((lang) {
                final isSelected = _selectedLanguage == lang;
                final isPressed = _pressedLang == lang;
                return GestureDetector(
                  onTapDown: (_) => setState(() => _pressedLang = lang),
                  onTapCancel: () => setState(() => _pressedLang = null),
                  onTapUp: (_) => setState(() => _pressedLang = null),
                  onTap: () => setState(() => _selectedLanguage = lang),
                  child: AnimatedScale(
                    scale: isPressed ? 0.96 : 1,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
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
        ],
      ),
    );
  }

  // PORTIONS SUMMARY components get their own translation now
  // (translations[lang].components[index], generated alongside everything
  // else - see utils/openaiClient.js's generateTranslations on the
  // backend), positionally aligned with recipe.components. Older recipes
  // generated before that existed have no such array (or a shorter one),
  // so this falls back to the previous heuristic: a component whose label
  // matches an ingredient's English name, case/whitespace insensitive, is
  // that ingredient (same convention RecipePreview._syncedIngredients uses
  // on the dietician side to keep quantities synced) and can borrow its
  // translated name. A composite label with no direct component
  // translation and no matching ingredient (e.g. an old "Warm Water with
  // Dates, Figs, Almonds, Walnuts" summary component) stays in English -
  // there's nothing to borrow from.
  String _componentLabel(int index, String label) {
    if (_selectedLanguage == 'English') return label;
    final t = widget.recipe.translations[_selectedLanguage];
    if (t == null) return label;
    if (index < t.components.length && t.components[index].label.isNotEmpty) {
      return t.components[index].label;
    }
    final needle = label.trim().toLowerCase();
    for (var i = 0; i < widget.recipe.ingredients.length; i++) {
      if (widget.recipe.ingredients[i].name.trim().toLowerCase() == needle) {
        if (i < t.ingredients.length && t.ingredients[i].name.isNotEmpty) {
          return t.ingredients[i].name;
        }
        break;
      }
    }
    return label;
  }

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
    return Stack(
      children: [
        CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            // Plain, naturally-sized header - drag handle, image, title. Not a
            // collapsing SliverAppBar: that meant force-fitting this content
            // into a manually-computed fixed height (see git history), which
            // kept overflowing in new ways (a long translated/AI-generated
            // title wrapping further than expected, a category badge changing
            // the available text width, ...) no matter how precisely the guess
            // was measured. A plain SliverToBoxAdapter has no height to get
            // wrong - it just sizes itself to whatever this Column actually
            // renders, the same way the portions/language card below it does.
            // Only the tab bar + its content stay a pinned "elevated sheet";
            // this part now scrolls away normally with the rest of the page.
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              image: CachedNetworkImageProvider(
                                widget.recipe.image,
                              ),
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
                ],
              ),
            ),

            // PORTIONS SUMMARY + LANGUAGE SELECTOR now live in their own
            // naturally-sized sliver instead of the fixed-height collapsing
            // header above - a Wrap of component chips can legitimately run
            // onto 2+ lines (many components, long translated labels), and a
            // sliver in normal flow just grows to fit that, so there's no
            // height to predict or get wrong. Reads as a second elevated sheet
            // (curved top, tinted background) stacked on the tab bar's sheet
            // below it, rather than one guessed-height slab.
            SliverToBoxAdapter(child: _buildPortionsAndLanguageCard()),

            // The tab bar's own curved-top "sheet" - stays pinned right below
            // the collapsed header, visually separating the tab content below
            // from the collapsing photo/title area above.
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                height: 66,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                        _buildTab(
                          2,
                          _isSupplement ? "Dosage" : "Cooking steps",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverFillRemaining(
              hasScrollBody: true,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                    ),
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
                                        border: cardBorder,
                                        boxShadow: cardShadow,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Divider(
                                    thickness: 0.7,
                                    color: Color(0xffFCCEEF),
                                  ),
                                ),
                                ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: widget.recipe.ingredients.length,
                                  itemBuilder: (context, index) {
                                    final data =
                                        widget.recipe.ingredients[index];
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
                ),
              ),
            ),
          ],
        ),
        // Pinned title bar - fades in over the content as it scrolls (see
        // _onScroll/_titleBarOpacity). A plain overlay, not part of the
        // sliver list, so it never reserves layout space of its own.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _titleBarOpacity,
            builder: (context, opacity, child) => IgnorePointer(
              ignoring: opacity == 0,
              child: Opacity(opacity: opacity, child: child),
            ),
            child: Container(
              height: kToolbarHeight,
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CustomText(
                text: recipeName,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xff384250),
              ),
            ),
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

/// The tab bar's curved-top "sheet" - pinned in place once scrolled under,
/// separating the Ingredients/Nutrition value/Cooking steps tab content
/// below from the collapsing header above it.
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _StickyTabBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
