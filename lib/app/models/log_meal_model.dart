
class LogMealData {
  final DateTime date;
  final bool isPresentDate;
  final List<ServingTimeModel> servingTimes;

  LogMealData({
    required this.date,
    required this.isPresentDate,
    required this.servingTimes,
  });

  factory LogMealData.fromJson(Map<String, dynamic> json) {
    return LogMealData(
      date: DateTime.parse(json['date']),
      isPresentDate: json['isPresentDate'] ?? false,
      servingTimes: (json['servingTimes'] as List<dynamic>? ?? [])
          .map((e) => ServingTimeModel.fromJson(e))
          .toList(),
    );
  }
}

// -------------------------------
// Serving Time Model
// -------------------------------
class ServingTimeModel {
  final String servingTime;
  final List<PlannedMealModel> plannedMeals;

  ServingTimeModel({
    required this.servingTime,
    required this.plannedMeals,
  });

  factory ServingTimeModel.fromJson(Map<String, dynamic> json) {
    return ServingTimeModel(
      servingTime: json['servingTime'] ?? '',
      plannedMeals: (json['plannedMeals'] as List<dynamic>? ?? [])
          .map((e) => PlannedMealModel.fromJson(e))
          .toList(),
    );
  }
}

// -------------------------------
// Planned Meal Model
// -------------------------------
class PlannedMealModel {
  final String recipeId;
  final String name;
  final String image;
  final int totalWeight;
  final String totalWeightUnit;
  final int calories;
  final int portion;

  PlannedMealModel({
    required this.recipeId,
    required this.name,
    required this.image,
    required this.totalWeight,
    required this.totalWeightUnit,
    required this.calories,
    required this.portion,
  });

  factory PlannedMealModel.fromJson(Map<String, dynamic> json) {
  return PlannedMealModel(
    recipeId: json['recipeId']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    image: json['image']?.toString() ?? '',
    totalWeight: json['totalWeight'] ?? 0,
    totalWeightUnit: json['totalWeightUnit']?.toString() ?? '',
    calories: json['calories'] ?? 0,
    portion: json['portion'] ?? 0,
  );
}

}
