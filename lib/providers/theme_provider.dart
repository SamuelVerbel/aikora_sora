import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider que controla el tema global de la aplicación (Claro/Oscuro).
/// Usa ChangeNotifier para que, cuando cambie el estado, la app entera
/// (MaterialApp en main.dart) se repinte automáticamente.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// Retorna el ThemeMode correspondiente para dárselo al MaterialApp
  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// El constructor se ejecuta al abrir la app. Carga el último tema guardado.
  ThemeProvider() {
    _loadTheme();
  }

  /// Cambia el tema, notifica a la UI y guarda la preferencia en la memoria del celular.
  void toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners(); // Avisa a Consumer<ThemeProvider> en main.dart

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
  }

  /// Lee la memoria local para recordar si el usuario prefirió modo oscuro la última vez.
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false; // false = modo claro por defecto
    notifyListeners();
  }
}
