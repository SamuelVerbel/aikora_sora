// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ── LIGHT ──────────────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.background,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.accent.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      side: const BorderSide(color: AppColors.border),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : Colors.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.accent.withOpacity(0.35)
            : Colors.grey.withOpacity(0.25),
      ),
    ),
    dividerColor: AppColors.border,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineMedium: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
  );

  // ── DARK ───────────────────────────────────────────────────────────────────
  static const _darkBg      = Color(0xFF0F172A);
  static const _darkSurface = Color(0xFF1E293B);
  static const _darkCard    = Color(0xFF1E293B);
  static const _darkBorder  = Color(0xFF334155);
  static const _darkText    = Color(0xFFF1F5F9);
  static const _darkSubtext = Color(0xFF94A3B8);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBg,
    primaryColor: AppColors.accent,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: _darkSurface,
      background: _darkBg,
      onBackground: _darkText,
      onSurface: _darkText,
      onPrimary: Colors.white,
      outline: _darkBorder,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBg,
      foregroundColor: _darkText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _darkText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: _darkText),
    ),
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: _darkSubtext),
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkText,
        side: const BorderSide(color: _darkBorder),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _darkSurface,
      selectedColor: AppColors.accent.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: _darkText),
      side: const BorderSide(color: _darkBorder),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : Colors.grey[600],
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.accent.withOpacity(0.35)
            : Colors.grey.withOpacity(0.2),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _darkSubtext,
      textColor: _darkText,
    ),
    dividerColor: _darkBorder,
    dividerTheme: const DividerThemeData(color: _darkBorder),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold, color: _darkText),
      headlineMedium: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: _darkText),
      bodyLarge:  TextStyle(fontSize: 16, color: _darkText),
      bodyMedium: TextStyle(fontSize: 14, color: _darkSubtext),
      bodySmall:  TextStyle(fontSize: 12, color: Color(0xFF64748B)),
    ),
  );
}
