import 'package:shared_preferences/shared_preferences.dart';

class UserBehaviorService {
  static const _viewedKey = 'viewed_destinations';
  static const _preferencesKey = 'user_preferences';

  /// Guarda destino visto
  Future<void> registerDestinationView(String destinationId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_viewedKey) ?? [];

    if (!list.contains(destinationId)) {
      list.add(destinationId);
      await prefs.setStringList(_viewedKey, list);
    }
  }

  Future<List<String>> getViewedDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_viewedKey) ?? [];
  }

  Future<void> savePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKey + key, value);
  }

  Future<String?> getPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferencesKey + key);
  }

  Future<void> learnTravelPreference(
    String destinationId,
    String category,
  ) 
  
  async {
    final prefs = await SharedPreferences.getInstance();

    // historial de categorías vistas
    final key = 'viewed_categories';
    final categories = prefs.getStringList(key) ?? [];

    categories.add(category.toLowerCase());
    await prefs.setStringList(key, categories);

    // contamos frecuencia
    final Map<String, int> counter = {};

    for (final c in categories) {
      counter[c] = (counter[c] ?? 0) + 1;
    }

    // buscamos la categoría dominante
    String? learnedCategory;
    int max = 0;

    counter.forEach((cat, count) {
      if (count >= 3 && count > max) {
        learnedCategory = cat;
        max = count;
      }
    });

    // guardamos preferencia automáticamente
    if (learnedCategory != null) {
      await savePreference('travel_type', learnedCategory!);
    }
  }
}