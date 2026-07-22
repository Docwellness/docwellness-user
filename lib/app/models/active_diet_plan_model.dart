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
  final WeekSummary weekSummary;
  final WeekData week;
  final Map<String, Recipe> recipes;

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
    required this.weekSummary,
    required this.week,
    required this.recipes,
  });

  factory ActiveDietData.fromJson(Map<String, dynamic> json) {
    final currentWeek = json['currentWeek'] ?? 0;
    final cycleNumber = json['cycleNumber'] ?? 1;
    return ActiveDietData(
      dietPlanId: json['dietPlanId'] ?? '',
      status: json['status'] ?? '',
      activationDate: json['activationDate'] ?? '',
      currentWeek: currentWeek,
      totalWeeks: json['totalWeeks'] ?? 4,
      cycleNumber: cycleNumber,
      displayWeek: json['displayWeek'] ?? ((cycleNumber - 1) * 4 + currentWeek),
      weekStartDate: json['weekStartDate'] != null
          ? DateTime.tryParse(json['weekStartDate'].toString())
          : null,
      weekEndDate: json['weekEndDate'] != null
          ? DateTime.tryParse(json['weekEndDate'].toString())
          : null,
      weekSummary: WeekSummary.fromJson(json['weekSummary'] ?? {}),
      week: WeekData.fromJson(json['week'] ?? {}),
      recipes: (json['recipes'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, Recipe.fromJson(value)),
      ),
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

  WeekData({required this.week, required this.dailyMeals});

  factory WeekData.fromJson(Map<String, dynamic> json) {
    return WeekData(
      week: json['week'] ?? 0,
      dailyMeals: (json['dailyMeals'] as List? ?? [])
          .map((e) => DailyMeal.fromJson(e))
          .toList(),
    );
  }
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

  DailyMeal({
    required this.servingTime,
    required this.recipeId,
    this.servings = 1,
  });

  factory DailyMeal.fromJson(Map<String, dynamic> json) {
    return DailyMeal(
      servingTime: json['servingTime'] ?? '',
      recipeId: json['recipeId'] ?? '',
      servings: (json['servings'] as num?) ?? 1,
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
    tags: tags,
    // Not portion-scaled - a supplement's active-ingredient facts are fixed
    // per its own serving (e.g. "1 tablet"), unrelated to servings ratio.
    supplementFacts: supplementFacts,
  );
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
