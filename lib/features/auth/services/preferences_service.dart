import 'package:shared_preferences/shared_preferences.dart';

/// Maneja las preferencias LOCALES del usuario.
/// Se guarda en el dispositivo, no en Supabase.
class PreferencesService {

  // Claves internas que usaremos en SharedPreferences
  static const _keyNature = 'likes_nature';
  static const _keyCulture = 'likes_culture';
  static const _keyFood = 'likes_food';
  static const _keyLanguage = 'language';
  static const _keyBudget = 'budget';

  /// Guarda las preferencias en SharedPreferences.
  /// Esta función se llama desde ProfileScreen cuando el usuario
  /// toca “Guardar preferencias”.
  static Future<void> savePreferences({
    required bool nature,
    required bool culture,
    required bool food,
    required String language,
    required double budget,
  }) async {
    // Obtiene una instancia de SharedPreferences (singleton)
    final prefs = await SharedPreferences.getInstance();

    // Guarda cada valor bajo su clave correspondiente
    await prefs.setBool(_keyNature, nature);
    await prefs.setBool(_keyCulture, culture);
    await prefs.setBool(_keyFood, food);
    await prefs.setString(_keyLanguage, language);
    await prefs.setDouble(_keyBudget, budget);
  }

  /// Carga las preferencias almacenadas.
  /// Si es la primera vez (no hay nada), devuelve valores por defecto.
  static Future<Map<String, dynamic>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      // Si no existe, asumimos que le gusta naturaleza y comida.
      'nature': prefs.getBool(_keyNature) ?? true,
      'culture': prefs.getBool(_keyCulture) ?? false,
      'food': prefs.getBool(_keyFood) ?? true,
      // Por defecto español y presupuesto 500 USD
      'language': prefs.getString(_keyLanguage) ?? 'es',
      'budget': prefs.getDouble(_keyBudget) ?? 500,
    };
  }
}
