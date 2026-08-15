/// One of today's assigned exercises, joined with whether it's already
/// logged - mirrors the shape of getTodayExerciseStats' plannedExercises.
class PlannedExercise {
  final String exerciseId;
  final String name;
  final String category;
  final String image;
  final String description;
  final String videoUrl;
  final List<String> instructions;
  // Optional - the dietician's suggested/target duration. Some exercises are
  // assigned by sets/reps alone (see ExercisePlan.js's own comment on the
  // backend). Your own actual duration is still required when you log
  // completion (see ExerciseController.logExercise) - this is just what
  // pre-fills that dialog when the dietician did set one.
  final num? durationMinutes;
  final num? sets;
  final num? reps;
  final bool isLogged;
  final num loggedCaloriesBurned;
  // Keyed by language name (e.g. "Hindi"), each value a {name, description,
  // instructions} map - see the backend's generateExerciseTranslations.
  // Read via RecipeLanguageService's shared app-wide language preference
  // (same one recipes use), not an exercise-specific setting.
  final Map<String, dynamic> translations;

  PlannedExercise({
    required this.exerciseId,
    required this.name,
    required this.category,
    required this.image,
    this.description = '',
    this.videoUrl = '',
    this.instructions = const [],
    this.durationMinutes,
    this.sets,
    this.reps,
    required this.isLogged,
    required this.loggedCaloriesBurned,
    this.translations = const {},
  });

  factory PlannedExercise.fromJson(Map<String, dynamic> json) {
    return PlannedExercise(
      exerciseId: json['exerciseId']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      instructions: List<String>.from(json['instructions'] ?? []),
      durationMinutes: json['durationMinutes'] as num?,
      sets: json['sets'] as num?,
      reps: json['reps'] as num?,
      isLogged: json['isLogged'] == true,
      loggedCaloriesBurned: (json['loggedCaloriesBurned'] as num?) ?? 0,
      translations: json['translations'] != null ? Map<String, dynamic>.from(json['translations']) : const {},
    );
  }

  String nameIn(String language) {
    if (language == 'English') return name;
    final t = translations[language];
    return (t is Map && t['name'] is String && (t['name'] as String).isNotEmpty) ? t['name'] : name;
  }

  String descriptionIn(String language) {
    if (language == 'English') return description;
    final t = translations[language];
    return (t is Map && t['description'] is String) ? t['description'] : description;
  }

  List<String> instructionsIn(String language) {
    if (language == 'English') return instructions;
    final t = translations[language];
    if (t is Map && t['instructions'] is List && (t['instructions'] as List).isNotEmpty) {
      return List<String>.from(t['instructions']);
    }
    return instructions;
  }
}

class ExerciseStats {
  final List<PlannedExercise> plannedExercises;
  final num totalCaloriesBurned;
  final int completedCount;
  final int totalExercises;

  ExerciseStats({
    required this.plannedExercises,
    required this.totalCaloriesBurned,
    required this.completedCount,
    required this.totalExercises,
  });

  factory ExerciseStats.fromJson(Map<String, dynamic> json) {
    return ExerciseStats(
      plannedExercises: (json['plannedExercises'] as List? ?? [])
          .map((e) => PlannedExercise.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalCaloriesBurned: (json['totalCaloriesBurned'] as num?) ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      totalExercises: (json['totalExercises'] as num?)?.toInt() ?? 0,
    );
  }

  factory ExerciseStats.empty() => ExerciseStats(
    plannedExercises: [],
    totalCaloriesBurned: 0,
    completedCount: 0,
    totalExercises: 0,
  );
}
