import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyNature = 'likes_nature';
  static const _keyCulture = 'likes_culture';
  static const _keyFood = 'likes_food';
  static const _keyLanguage = 'language';
  static const _keyBudget = 'budget';

  // Guardar preferencias
  static Future<void> savePreferences({
    required bool nature,
    required bool culture,
    required bool food,
    required String language,
    required double budget,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyNature, nature);
    await prefs.setBool(_keyCulture, culture);
    await prefs.setBool(_keyFood, food);
    await prefs.setString(_keyLanguage, language);
    await prefs.setDouble(_keyBudget, budget);
  }

  // Cargar preferencias
  static Future<Map<String, dynamic>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'nature': prefs.getBool(_keyNature) ?? true,
      'culture': prefs.getBool(_keyCulture) ?? false,
      'food': prefs.getBool(_keyFood) ?? true,
      'language': prefs.getString(_keyLanguage) ?? 'es',
      'budget': prefs.getDouble(_keyBudget) ?? 500,
    };
  }
}
