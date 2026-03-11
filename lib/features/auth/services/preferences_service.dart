import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Preferencias principales
  static const _keyNature = 'likes_nature';
  static const _keyCulture = 'likes_culture';
  static const _keyFood = 'likes_food';
  static const _keyAdventure = 'likes_adventure';
  static const _keyBeach = 'likes_beach';

  static const _keyLanguage = 'language';
  static const _keyBudget = 'budget';

  // IA y filtros (RF-06)
  static const _keyMinRating = 'min_rating';
  static const _keyClimate = 'preferred_climate';

  /// Guarda TODO el perfil (ProfileScreen)
  static Future<void> savePreferences({
    required bool nature,
    required bool culture,
    required bool food,
    required bool adventure,
    required bool beach,
    required String language,
    required double budget,
    double minRating = 0.0,
    String climate = 'Todos',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyNature, nature);
    await prefs.setBool(_keyCulture, culture);
    await prefs.setBool(_keyFood, food);
    await prefs.setBool(_keyAdventure, adventure);
    await prefs.setBool(_keyBeach, beach);

    await prefs.setString(_keyLanguage, language);
    await prefs.setDouble(_keyBudget, budget);

    await prefs.setDouble(_keyMinRating, minRating);
    await prefs.setString(_keyClimate, climate);
  }

  /// Guarda SOLO presupuesto (Explore slider)
  static Future<void> saveBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBudget, budget);
  }

  /// Guarda SOLO clima
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
      'adventure': prefs.getBool(_keyAdventure) ?? false,
      'beach': prefs.getBool(_keyBeach) ?? false,
      'language': prefs.getString(_keyLanguage) ?? 'es',
      'budget': prefs.getDouble(_keyBudget) ?? 500.0,
      'minRating': prefs.getDouble(_keyMinRating) ?? 0.0,
      'climate': prefs.getString(_keyClimate) ?? 'Todos',
    };
  }
}