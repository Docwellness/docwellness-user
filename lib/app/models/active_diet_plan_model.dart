class ActiveDietData {
  final String dietPlanId;
  final String status;
  final String activationDate;
  final int currentWeek;
  final int totalWeeks;
  // Which renewal cycle this plan belongs to (1 = first plan ever built for
  // this patient, incremented per renewal - see backend's DietPlan.js). Not
  // conflated with totalWeeks, which stays "weeks in this cycle" (still 4).
  final int cycleNumber;
  // (cycleNumber-1)*4 + currentWeek - what to actually show the patient
  // ("Week 5") once they've renewed at least once.
  final int displayWeek;
  final DateTime? weekStartDate;
  final DateTime? weekEndDate;
  // The real currently-active week's start date (i.e. weekStartDate as it
  // was on the initial fetch, before any client-side switchWeek). Unlike
  // weekStartDate - which copyWithWeek below overwrites with whichever
  // week the patient is browsing - this never changes, so diet_view.dart's
  // "hasn't started yet" gate keeps gating on whether the plan itself has
  // begun, not on whether some future week the patient tapped ahead into
  // (e.g. Week 2, finalized but not due to start for days) has begun.
  final DateTime? planStartDate;
  final WeekSummary weekSummary;
  final WeekData week;
  final Map<String, Recipe> recipes;
  // Every week the plan has, day-group-filtered the same way `week` above
  // is - lets the app cache the whole plan on first fetch and switch weeks
  // client-side (no network round trip / loading spinner per tap).
  final List<WeekEntry> weeks;

  ActiveDietData({
    required this.dietPlanId,
    required this.status,
    required this.activationDate,
    required this.currentWeek,
    required this.totalWeeks,
    required this.cycleNumber,
    required this.displayWeek,
    this.weekStartDate,
    this.weekEndDate,
    this.planStartDate,
    required this.weekSummary,
    required this.week,
    required this.recipes,
    this.weeks = const [],
  });

  factory ActiveDietData.fromJson(Map<String, dynamic> json) {
    final currentWeek = json['currentWeek'] ?? 0;
    final cycleNumber = json['cycleNumber'] ?? 1;
    final parsedWeekStartDate = json['weekStartDate'] != null
        ? DateTime.tryParse(json['weekStartDate'].toString())
        : null;
    return ActiveDietData(
      dietPlanId: json['dietPlanId'] ?? '',
      status: json['status'] ?? '',
      activationDate: json['activationDate'] ?? '',
      currentWeek: currentWeek,
      totalWeeks: json['totalWeeks'] ?? 4,
      cycleNumber: cycleNumber,
      displayWeek: json['displayWeek'] ?? ((cycleNumber - 1) * 4 + currentWeek),
      weekStartDate: parsedWeekStartDate,
      weekEndDate: json['weekEndDate'] != null
          ? DateTime.tryParse(json['weekEndDate'].toString())
          : null,
      planStartDate: parsedWeekStartDate,
      weekSummary: WeekSummary.fromJson(json['weekSummary'] ?? {}),
      week: WeekData.fromJson(json['week'] ?? {}),
      recipes: (json['recipes'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, Recipe.fromJson(value)),
      ),
      weeks: (json['weeks'] as List? ?? [])
          .map((e) => WeekEntry.fromJson(e))
          .toList(),
    );
  }

  /// Swaps in a different (already-cached) week's data without a network
  /// call - see DietController.switchWeek. planStartDate is deliberately
  /// carried over unchanged (not entry.weekStartDate) - see its own doc
  /// comment.
  ActiveDietData copyWithWeek(WeekEntry entry) => ActiveDietData(
    dietPlanId: dietPlanId,
    status: status,
    activationDate: activationDate,
    currentWeek: entry.week,
    totalWeeks: totalWeeks,
    cycleNumber: cycleNumber,
    displayWeek: (cycleNumber - 1) * 4 + entry.week,
    weekStartDate: entry.weekStartDate,
    weekEndDate: entry.weekEndDate,
    planStartDate: planStartDate,
    weekSummary: entry.weekSummary ?? weekSummary,
    week: WeekData(
      week: entry.week,
      dailyMeals: entry.dailyMeals,
      supplementSchedule: entry.supplementSchedule,
    ),
    recipes: recipes,
    weeks: weeks,
  );
}

// -----------------------------
// One cached week entry (see ActiveDietData.weeks)
// -----------------------------
class WeekEntry {
  final int week;
  final DateTime? weekStartDate;
  final DateTime? weekEndDate;
  final WeekSummary? weekSummary;
  final List<DailyMeal> dailyMeals;
  final List<SupplementScheduleEntry> supplementSchedule;

  WeekEntry({
    required this.week,
    this.weekStartDate,
    this.weekEndDate,
    this.weekSummary,
    required this.dailyMeals,
    this.supplementSchedule = const [],
  });

  factory WeekEntry.fromJson(Map<String, dynamic> json) {
    return WeekEntry(
      week: json['week'] ?? 0,
      weekStartDate: json['weekStartDate'] != null
          ? DateTime.tryParse(json['weekStartDate'].toString())
          : null,
      weekEndDate: json['weekEndDate'] != null
          ? DateTime.tryParse(json['weekEndDate'].toString())
          : null,
      weekSummary: json['weekSummary'] != null
          ? WeekSummary.fromJson(json['weekSummary'])
          : null,
      dailyMeals: (json['dailyMeals'] as List? ?? [])
          .map((e) => DailyMeal.fromJson(e))
          .toList(),
      supplementSchedule: (json['supplementSchedule'] as List? ?? [])
          .map((e) => SupplementScheduleEntry.fromJson(e))
          .toList(),
    );
  }
}

// -----------------------------
// Week Summary Data
// -----------------------------
class WeekSummary {
  final int week;
  final int totalCalories;
  final int fatPercent;
  final int fatGrams;
  final int carbPercent;
  final int carbGrams;
  final int proteinPercent;
  final int proteinGrams;
  final int fiberGrams;
  final String id;

  WeekSummary({
    required this.week,
    required this.totalCalories,
    required this.fatPercent,
    required this.fatGrams,
    required this.carbPercent,
    required this.carbGrams,
    required this.proteinPercent,
    required this.proteinGrams,
    required this.fiberGrams,
    required this.id,
  });

  factory WeekSummary.fromJson(Map<String, dynamic> json) {
    return WeekSummary(
      week: json['week'] ?? 0,
      totalCalories: json['totalCalories'] ?? 0,
      fatPercent: json['fatPercent'] ?? 0,
      fatGrams: json['fatGrams'] ?? 0,
      carbPercent: json['carbPercent'] ?? 0,
      carbGrams: json['carbGrams'] ?? 0,
      proteinPercent: json['proteinPercent'] ?? 0,
      proteinGrams: json['proteinGrams'] ?? 0,
      fiberGrams: json['fiberGrams'] ?? 0,
      id: json['_id'] ?? '',
    );
  }
}

// -----------------------------
// Week Data
// -----------------------------
class WeekData {
  final int week;
  final List<DailyMeal> dailyMeals;
  // Timed supplements (dosage/instructions/timingAnchor) injected via the
  // dietician wizard's Timeline Builder - a separate list from dailyMeals
  // entirely (a plain recipe selection has no timing/dosage fields), see
  // backend's getActiveDietPlanForPatient. Empty for any plan that hasn't
  // had a supplement injected this way.
  final List<SupplementScheduleEntry> supplementSchedule;

  WeekData({
    required this.week,
    required this.dailyMeals,
    this.supplementSchedule = const [],
  });

  factory WeekData.fromJson(Map<String, dynamic> json) {
    return WeekData(
      week: json['week'] ?? 0,
      dailyMeals: (json['dailyMeals'] as List? ?? [])
          .map((e) => DailyMeal.fromJson(e))
          .toList(),
      supplementSchedule: (json['supplementSchedule'] as List? ?? [])
          .map((e) => SupplementScheduleEntry.fromJson(e))
          .toList(),
    );
  }
}

// -----------------------------
// Supplement Schedule Entry (timing-anchored supplement, see Timeline
// Builder's Supplement Injection on the dietician side)
// -----------------------------
class SupplementScheduleEntry {
  final String dayGroup;
  final String servingTime;
  final String supplementId;
  final String? dosage;
  final String? instructions;
  // 'pre' | 'with' | 'post' - relative to servingTime, e.g. "Before
  // Breakfast" / "With Lunch" / "After Dinner".
  final String timingAnchor;

  SupplementScheduleEntry({
    required this.dayGroup,
    required this.servingTime,
    required this.supplementId,
    this.dosage,
    this.instructions,
    required this.timingAnchor,
  });

  factory SupplementScheduleEntry.fromJson(Map<String, dynamic> json) {
    return SupplementScheduleEntry(
      dayGroup: json['dayGroup'] ?? '',
      servingTime: json['servingTime'] ?? '',
      supplementId: json['supplementId'] ?? '',
      dosage: json['dosage'],
      instructions: json['instructions'],
      timingAnchor: json['timingAnchor'] ?? 'with',
    );
  }

  static const Map<String, String> _anchorPrefixLabels = {
    'pre': 'Before',
    'with': 'With',
    'post': 'After',
  };

  /// e.g. "Before Breakfast" / "With Lunch" / "After Dinner" - the timeline
  /// sub-header shown above this supplement's card.
  String get timingLabel =>
      '${_anchorPrefixLabels[timingAnchor] ?? 'With'} $servingTime';
}

// -----------------------------
// Daily Meal
// -----------------------------
class DailyMeal {
  final String servingTime;
  final String recipeId;
  // How many servings the dietician actually prescribed for this slot (e.g.
  // 3 for "3 chapatis", or 400 for "400g of Chole") - defaults to 1, which
  // for a piece-based recipe means "the recipe's own single base serving"
  // and for a gram/ml-based recipe means "1 gram/ml" only in the legacy
  // case where a plan was finalized before this field existed.
  final num servings;
  // Which of the week's 4 day-groups (Monday=Friday, Tuesday=Saturday,
  // Wednesday=Sunday, Thursday unique - see backend's utils/dayGroups.js)
  // this meal belongs to. A week's dailyMeals now carries all 4 groups
  // together in one response (see getActiveDietPlanForPatient) - null/empty
  // means pre-migration data that applies to every group, mirroring the
  // backend's mealMatchesDayGroup fallback.
  final String? dayGroup;
  // Per-component quantity override for a compound recipe (see
  // Recipe.components) - same order as the recipe's own components list,
  // e.g. [3, 1, 2] for Idli/Sambar/Chutney. Null/empty means every
  // component uses its recipe-default quantity scaled by the same overall
  // `servings` ratio (legacy meals saved before per-component editing
  // existed, or a recipe that's never had this meal's selection re-saved).
  final List<num>? componentServings;

  DailyMeal({
    required this.servingTime,
    required this.recipeId,
    this.servings = 1,
    this.dayGroup,
    this.componentServings,
  });

  factory DailyMeal.fromJson(Map<String, dynamic> json) {
    final rawComponentServings = json['componentServings'];
    return DailyMeal(
      servingTime: json['servingTime'] ?? '',
      recipeId: json['recipeId'] ?? '',
      servings: (json['servings'] as num?) ?? 1,
      dayGroup: json['dayGroup']?.toString(),
      componentServings: rawComponentServings is List
          ? rawComponentServings.whereType<num>().toList()
          : null,
    );
  }
}

// -----------------------------
// Recipe
// -----------------------------
class Recipe {
  final String id;
  final String name;
  final String servingTime;
  final String image;
  final ServingSize servingSize;
  final Nutrition nutritionPerServing;
  final Nutrition nutrition;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final List<String> languages;
  final Map<String, RecipeTranslation> translations;
  // Independently-adjustable parts of a compound dish (e.g. Idli: 3 nos,
  // Sambar: 1 bowl, Chutney: 2 tbsp) - empty for an ordinary single-quantity
  // recipe. Mirrors the dietician app's identical RecipeComponent (see
  // ai_diet_plain_model.dart there), so a multi-part meal shows the same
  // per-component units on both apps instead of collapsing to just its
  // first part.
  final List<RecipeComponent> components;
  // e.g. ['supplement'], ['side'], ['salad'] - drives the dedicated
  // Supplements tab on the patient's Diet Plan screen (see
  // DietController.getSupplementRecipes).
  final List<String> tags;
  // Real per-serving active-ingredient facts for a supplement - null for
  // every ordinary food recipe. When present, the app shows these instead
  // of the (zeroed, meaningless) calorie/protein/fiber/carbs/fat numbers -
  // mirrors the dietician app's identical SupplementFacts/SupplementNutrient
  // (see ai_diet_plain_model.dart there).
  final SupplementFacts? supplementFacts;

  Recipe({
    required this.id,
    required this.name,
    required this.servingTime,
    required this.image,
    required this.servingSize,
    required this.nutritionPerServing,
    required this.nutrition,
    required this.ingredients,
    required this.instructions,
    this.languages = const ['English'],
    this.translations = const {},
    this.components = const [],
    this.tags = const [],
    this.supplementFacts,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Parse language field - can be a string or list
    List<String> parsedLanguages;
    if (json['language'] is List) {
      parsedLanguages = List<String>.from(json['language']);
    } else if (json['language'] is String && json['language'] != null) {
      parsedLanguages = (json['language'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    } else {
      parsedLanguages = ['English'];
    }

    // Parse translations map
    Map<String, RecipeTranslation> parsedTranslations = {};
    if (json['translations'] is Map) {
      (json['translations'] as Map).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedTranslations[key.toString()] = RecipeTranslation.fromJson(
            value,
          );
        }
      });
    }

    return Recipe(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      servingTime: json['servingTime'] ?? '',
      image: json['image'] ?? '',
      servingSize: ServingSize.fromJson(json['servingSize'] ?? {}),
      nutritionPerServing: Nutrition.fromJson(
        json['nutritionPerServing'] ?? {},
      ),
      nutrition: Nutrition.fromJson(json['nutrition'] ?? {}),
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => Ingredient.fromJson(e))
          .toList(),
      instructions: List<String>.from(json['instructions'] ?? []),
      languages: parsedLanguages,
      translations: parsedTranslations,
      components: (json['components'] as List? ?? [])
          .map((e) => RecipeComponent.fromJson(e))
          .toList(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      supplementFacts: json['supplementFacts'] != null
          ? SupplementFacts.fromJson(json['supplementFacts'])
          : null,
    );
  }

  // Returns a copy scaled to the dietician-prescribed servings for a
  // specific occurrence of this recipe (e.g. "400g Chole" vs the recipe's
  // own base "350g") - mirrors the ratio math already used dietician-side
  // (patients_controller.dart's _servingsRatio) so a given servings value
  // produces the same nutrition on both apps.
  Recipe scaledBy(num ratio) => Recipe(
    id: id,
    name: name,
    servingTime: servingTime,
    image: image,
    servingSize: ServingSize(
      servings: servingSize.servings,
      quantity: servingSize.quantity * ratio,
      unit: servingSize.unit,
    ),
    nutritionPerServing: nutritionPerServing.scaledBy(ratio),
    nutrition: nutrition.scaledBy(ratio),
    ingredients: ingredients,
    instructions: instructions,
    languages: languages,
    translations: translations,
    components: components
        .map((c) => RecipeComponent(
              label: c.label,
              quantity: c.quantity * ratio,
              unit: c.unit,
            ))
        .toList(),
    tags: tags,
    // Not portion-scaled - a supplement's active-ingredient facts are fixed
    // per its own serving (e.g. "1 tablet"), unrelated to servings ratio.
    supplementFacts: supplementFacts,
  );

  // Returns a copy with only `components` replaced - used when a meal
  // carries an explicit per-component override (DailyMeal.componentServings,
  // e.g. the dietician bumped just the Sambar to 2 bowls) so each
  // component's real assigned quantity is shown instead of the uniform
  // scaledBy ratio applied to every component alike.
  Recipe withComponents(List<RecipeComponent> newComponents) => Recipe(
    id: id,
    name: name,
    servingTime: servingTime,
    image: image,
    servingSize: servingSize,
    nutritionPerServing: nutritionPerServing,
    nutrition: nutrition,
    ingredients: ingredients,
    instructions: instructions,
    languages: languages,
    translations: translations,
    components: newComponents,
    tags: tags,
    supplementFacts: supplementFacts,
  );
}

/// One independently-adjustable part of a compound dish (e.g. "Idli", 3,
/// "nos") - mirrors the dietician app's identical RecipeComponent exactly
/// (see ai_diet_plain_model.dart there).
class RecipeComponent {
  final String label;
  final num quantity;
  final String unit;

  RecipeComponent({
    required this.label,
    required this.quantity,
    required this.unit,
  });

  factory RecipeComponent.fromJson(Map<String, dynamic> json) {
    return RecipeComponent(
      label: json['label'] ?? '',
      quantity: (json['quantity'] as num?) ?? 1,
      unit: json['unit'] ?? 'g',
    );
  }
}

/// Translation data for a recipe in a specific language
class RecipeTranslation {
  final String name;
  final String description;
  final List<IngredientTranslation> ingredients;
  final List<String> cookingSteps;
  final List<String> warnings;

  RecipeTranslation({
    required this.name,
    this.description = '',
    required this.ingredients,
    required this.cookingSteps,
    this.warnings = const [],
  });

  factory RecipeTranslation.fromJson(Map<String, dynamic> json) {
    return RecipeTranslation(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map(
                (e) => IngredientTranslation.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ),
              )
              .toList() ??
          [],
      cookingSteps: List<String>.from(json['cookingSteps'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}

/// Translated ingredient name and description
class IngredientTranslation {
  final String name;
  final String description;

  IngredientTranslation({required this.name, this.description = ''});

  factory IngredientTranslation.fromJson(Map<String, dynamic> json) {
    return IngredientTranslation(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

// -----------------------------
// Serving Size
// -----------------------------
class ServingSize {
  final int servings;
  // num, not int - a scaled quantity (e.g. 400/350 * 350 = 400, but other
  // ratios produce fractional grams/ml) must not be truncated.
  final num quantity;
  final String unit;

  ServingSize({
    required this.servings,
    required this.quantity,
    required this.unit,
  });

  factory ServingSize.fromJson(Map<String, dynamic> json) {
    return ServingSize(
      servings: json['servings'] ?? 0,
      quantity: (json['quantity'] as num?) ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

// -----------------------------
// Nutrition Data
// -----------------------------
class Nutrition {
  // num, not int - recipe nutrition values can be fractional (e.g. a
  // "Flaxseed Water" recipe has protein: 1.9, fats: 4.3 in the DB).
  // Assigning a double JSON value into an int-typed field throws a runtime
  // TypeError in Dart - `?? 0` only guards null, not a type mismatch - which
  // would silently crash parsing of this patient's entire active diet plan
  // whenever it included such a recipe.
  final num calories;
  final num protein;
  final num carbs;
  final num fats;
  final num fiber;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: (json['calories'] as num?) ?? 0,
      protein: (json['protein'] as num?) ?? 0,
      carbs: (json['carbs'] as num?) ?? 0,
      fats: (json['fats'] as num?) ?? 0,
      fiber: (json['fiber'] as num?) ?? 0,
    );
  }

  Nutrition scaledBy(num ratio) => Nutrition(
    calories: calories * ratio,
    protein: protein * ratio,
    carbs: carbs * ratio,
    fats: fats * ratio,
    fiber: fiber * ratio,
  );
}

// -----------------------------
// Ingredient
// -----------------------------
class Ingredient {
  final String name;
  final num quantity;
  final String unit;
  final String image;
  final bool isScalable;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.image,
    required this.isScalable,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
      image: json['image'] ?? '',
      isScalable: json['isScalable'] ?? false,
    );
  }
}

// ---------------------------
// SupplementFacts
// ---------------------------
/// Real per-serving active-ingredient facts for a supplement recipe (see
/// backend models/Recipe.js's `supplementFacts`) - a vitamin/mineral
/// tablet's meaningful numbers are its ingredient amounts and %NRV, not
/// calories/protein/carbs/fats. Mirrors the dietician app's identical
/// SupplementFacts/SupplementNutrient exactly (ai_diet_plain_model.dart).
class SupplementFacts {
  final String brand;
  final num servingQuantity;
  final String servingUnit;
  final String servingLabel;
  final num? servingsPerContainer;
  final List<SupplementNutrient> nutrients;

  SupplementFacts({
    required this.brand,
    required this.servingQuantity,
    required this.servingUnit,
    required this.servingLabel,
    required this.servingsPerContainer,
    required this.nutrients,
  });

  factory SupplementFacts.fromJson(Map<String, dynamic> json) {
    final servingSize = json["servingSize"] as Map<String, dynamic>?;
    return SupplementFacts(
      brand: json["brand"] ?? '',
      servingQuantity: (servingSize?["quantity"] as num?) ?? 1,
      servingUnit: servingSize?["unit"] ?? '',
      servingLabel: servingSize?["label"] ?? '',
      servingsPerContainer: json["servingsPerContainer"] as num?,
      nutrients:
          (json["nutrients"] as List?)
              ?.map((e) => SupplementNutrient.fromJson(e))
              .toList() ??
          const [],
    );
  }
}

class SupplementNutrient {
  final String name;
  final num amount;
  final String unit;
  final num? percentNRV;

  SupplementNutrient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.percentNRV,
  });

  factory SupplementNutrient.fromJson(Map<String, dynamic> json) {
    return SupplementNutrient(
      name: json["name"] ?? '',
      amount: (json["amount"] as num?) ?? 0,
      unit: json["unit"] ?? '',
      percentNRV: json["percentNRV"] as num?,
    );
  }

  /// e.g. "Zinc 15mg · 150% NRV", or "Lutein 1500µg" when the label has no
  /// %NRV for this nutrient.
  String get displayLabel {
    final amountLabel = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    final base = '$name $amountLabel$unit';
    if (percentNRV == null) return base;
    final nrvLabel = percentNRV == percentNRV!.roundToDouble()
        ? percentNRV!.toInt().toString()
        : percentNRV.toString();
    return '$base · $nrvLabel% NRV';
  }
}
