import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The patient's preferred language for viewing recipe content (name,
/// ingredients, cooking steps) - editable from Settings ("Recipe
/// Language"), and read by RecipeDetailsScreen to decide which language a
/// recipe opens in by default. Persisted so it survives app restarts; an
/// Rx so any screen reading it (e.g. Settings' own trailing label) updates
/// live the instant it changes.
class RecipeLanguageService {
  RecipeLanguageService._();
  static final RecipeLanguageService instance = RecipeLanguageService._();

  static const String _prefsKey = 'recipeLanguage';
  static const String defaultLanguage = 'English';
  static const List<String> supportedLanguages = [
    'English',
    'Hindi',
    'Marathi',
  ];

  final RxString current = defaultLanguage.obs;
  bool _loaded = false;

  /// Loads the stored preference (if any) - idempotent and safe to call
  /// from multiple screens; only the first call actually hits disk.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null && supportedLanguages.contains(stored)) {
      current.value = stored;
    }
  }

  Future<void> setLanguage(String language) async {
    if (!supportedLanguages.contains(language)) return;
    current.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language);
  }
}
