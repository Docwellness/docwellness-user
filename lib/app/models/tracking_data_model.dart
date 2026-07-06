/// Model for patient tracking data (calorie intake, weight trend, BMI)
class TrackingData {
  final String period;
  final DateRangeLabel dateRange;
  final int currentIndex;
  final double currentWeight;
  final double currentBmi;
  final double targetWeight;
  final String activityLevel;
  final List<String> healthConcerns;
  final int plannedDailyCalories;
  final int tdee;
  final BodyMeasurements bodyMeasurements;
  final List<Achievement> achievements;
  final List<CalorieDataPoint> calorieData;
  final List<WeightDataPoint> weightTrend;
  final List<BmiDataPoint> bmiTrend;

  TrackingData({
    required this.period,
    required this.dateRange,
    required this.currentIndex,
    required this.currentWeight,
    required this.currentBmi,
    required this.targetWeight,
    required this.activityLevel,
    required this.healthConcerns,
    required this.plannedDailyCalories,
    required this.tdee,
    required this.bodyMeasurements,
    required this.achievements,
    required this.calorieData,
    required this.weightTrend,
    required this.bmiTrend,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      period: json['period'] ?? 'week',
      dateRange: DateRangeLabel.fromJson(json['dateRange'] ?? {}),
      currentIndex: _toInt(json['currentIndex']),
      currentWeight: _toDouble(json['currentWeight']),
      currentBmi: _toDouble(json['currentBmi']),
      targetWeight: _toDouble(json['targetWeight']),
      activityLevel: (json['activityLevel'] ?? '').toString(),
      healthConcerns:
          (json['healthConcerns'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      plannedDailyCalories: _toInt(json['plannedDailyCalories']),
      tdee: _toInt(json['tdee']),
      bodyMeasurements: BodyMeasurements.fromJson(
        json['bodyMeasurements'] ?? {},
      ),
      achievements:
          (json['achievements'] as List?)
              ?.map((e) => Achievement.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      calorieData:
          (json['calorieData'] as List?)
              ?.map(
                (e) => CalorieDataPoint.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      weightTrend:
          (json['weightTrend'] as List?)
              ?.map(
                (e) => WeightDataPoint.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      bmiTrend:
          (json['bmiTrend'] as List?)
              ?.map((e) => BmiDataPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  final raw = value.toString().trim();
  final direct = double.tryParse(raw);
  if (direct != null) return direct;

  // Handles values like "2 kg", "34.5kg", "~12.0"
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(raw);
  if (match != null) {
    return double.tryParse(match.group(0)!) ?? 0;
  }

  return 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ??
      (double.tryParse(value.toString())?.round() ?? 0);
}

class BodyMeasurements {
  final double arm;
  final double waist;
  final double hip;

  BodyMeasurements({required this.arm, required this.waist, required this.hip});

  factory BodyMeasurements.fromJson(Map<String, dynamic> json) {
    return BodyMeasurements(
      arm: _toDouble(json['arm']),
      waist: _toDouble(json['waist']),
      hip: _toDouble(json['hip']),
    );
  }
}

class Achievement {
  final String type;
  final String title;
  final String description;
  final String icon;

  Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
    );
  }
}

class DateRangeLabel {
  final String start;
  final String end;

  DateRangeLabel({required this.start, required this.end});

  factory DateRangeLabel.fromJson(Map<String, dynamic> json) {
    return DateRangeLabel(start: json['start'] ?? '', end: json['end'] ?? '');
  }
}

class CalorieDataPoint {
  final String label;
  final String? date;
  final String? dateRange;
  final int calories;
  final int? totalCalories;
  final int plannedCalories;
  final int? mealsLogged;
  final int? daysLogged;

  CalorieDataPoint({
    required this.label,
    this.date,
    this.dateRange,
    required this.calories,
    this.totalCalories,
    required this.plannedCalories,
    this.mealsLogged,
    this.daysLogged,
  });

  factory CalorieDataPoint.fromJson(Map<String, dynamic> json) {
    return CalorieDataPoint(
      label: (json['label'] ?? '').toString(),
      date: json['date']?.toString(),
      dateRange: json['dateRange']?.toString(),
      calories: _toInt(json['calories']),
      totalCalories: json['totalCalories'] == null
          ? null
          : _toInt(json['totalCalories']),
      plannedCalories: _toInt(json['plannedCalories']),
      mealsLogged: json['mealsLogged'] == null
          ? null
          : _toInt(json['mealsLogged']),
      daysLogged: json['daysLogged'] == null
          ? null
          : _toInt(json['daysLogged']),
    );
  }
}

class WeightDataPoint {
  final String label;
  final String date;
  final double weight;

  WeightDataPoint({
    required this.label,
    required this.date,
    required this.weight,
  });

  factory WeightDataPoint.fromJson(Map<String, dynamic> json) {
    return WeightDataPoint(
      label: (json['label'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      weight: _toDouble(json['weight']),
    );
  }
}

class BmiDataPoint {
  final String label;
  final String date;
  final double bmi;
  final double weight;

  BmiDataPoint({
    required this.label,
    required this.date,
    required this.bmi,
    required this.weight,
  });

  factory BmiDataPoint.fromJson(Map<String, dynamic> json) {
    return BmiDataPoint(
      label: (json['label'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      bmi: _toDouble(json['bmi']),
      weight: _toDouble(json['weight']),
    );
  }
}
