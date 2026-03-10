import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Claves existentes
  static const _keyNature = 'likes_nature';
  static const _keyCulture = 'likes_culture';
  static const _keyFood = 'likes_food';
  static const _keyLanguage = 'language';
  static const _keyBudget = 'budget';

  // NUEVAS CLAVES para la IA y Filtros (RF-06)
  static const _keyMinRating = 'min_rating';
  static const _keyClimate = 'preferred_climate';

  /// Guarda TODO el perfil (Usado en ProfileScreen)
  static Future<void> savePreferences({
    required bool nature,
    required bool culture,
    required bool food,
    required String language,
    required double budget,
    double minRating = 0.0,
    String climate = 'Todos',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNature, nature);
    await prefs.setBool(_keyCulture, culture);
    await prefs.setBool(_keyFood, food);
    await prefs.setString(_keyLanguage, language);
    await prefs.setDouble(_keyBudget, budget);
    await prefs.setDouble(_keyMinRating, minRating);
    await prefs.setString(_keyClimate, climate);
  }

  /// NUEVO: Guarda SOLO el presupuesto (Útil para el Slider de Explore)
  static Future<void> saveBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBudget, budget);
  }

  /// NUEVO: Guarda SOLO el clima
  static Future<void> saveClimate(String climate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyClimate, climate);
  }

  /// Carga todas las preferencias
  static Future<Map<String, dynamic>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'nature': prefs.getBool(_keyNature) ?? true,
      'culture': prefs.getBool(_keyCulture) ?? false,
      'food': prefs.getBool(_keyFood) ?? true,
      'language': prefs.getString(_keyLanguage) ?? 'es',
      'budget': prefs.getDouble(_keyBudget) ?? 5000.0, // Subimos el default
      'minRating': prefs.getDouble(_keyMinRating) ?? 0.0,
      'climate': prefs.getString(_keyClimate) ?? 'Todos',
    };
  }
}