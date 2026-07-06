class ActiveDietData {
  final String dietPlanId;
  final String status;
  final String activationDate;
  final int currentWeek;
  final int totalWeeks;
  final WeekSummary weekSummary;
  final WeekData week;
  final Map<String, Recipe> recipes;

  ActiveDietData({
    required this.dietPlanId,
    required this.status,
    required this.activationDate,
    required this.currentWeek,
    required this.totalWeeks,
    required this.weekSummary,
    required this.week,
    required this.recipes,
  });

  factory ActiveDietData.fromJson(Map<String, dynamic> json) {
    return ActiveDietData(
      dietPlanId: json['dietPlanId'] ?? '',
      status: json['status'] ?? '',
      activationDate: json['activationDate'] ?? '',
      currentWeek: json['currentWeek'] ?? 0,
      totalWeeks: json['totalWeeks'] ?? 4,
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

  DailyMeal({required this.servingTime, required this.recipeId});

  factory DailyMeal.fromJson(Map<String, dynamic> json) {
    return DailyMeal(
      servingTime: json['servingTime'] ?? '',
      recipeId: json['recipeId'] ?? '',
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
  final int quantity;
  final String unit;

  ServingSize({
    required this.servings,
    required this.quantity,
    required this.unit,
  });

  factory ServingSize.fromJson(Map<String, dynamic> json) {
    return ServingSize(
      servings: json['servings'] ?? 0,
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

// -----------------------------
// Nutrition Data
// -----------------------------
class Nutrition {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int fiber;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fats: json['fats'] ?? 0,
      fiber: json['fiber'] ?? 0,
    );
  }
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
