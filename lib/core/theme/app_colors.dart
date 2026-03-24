import 'package:flutter/material.dart';

class AppColors {
  // ── Colores base (modo oscuro) ────────────────────────────────────────────
  static const Color primary    = Color(0xFF0D1117);
  static const Color accent     = Color(0xFF00C4F0); // Cyan premium, ligeramente más profundo
  static const Color accentSoft = Color(0xFF00D1FF); // Cyan original para gradientes
  static const Color background = Color(0xFF010409);
  static const Color surface    = Color(0xFF161B22);
  static const Color surfaceElevated = Color(0xFF1C2128); // Para cards sobre surface

  // ── Modo claro ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF2F4F7);
  static const Color lightSurface    = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFF8FAFC);
  static const Color lightText       = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const Color textMain      = Colors.white;
  static const Color textSecondary = Color(0xFF8B949E);

  // ── Gradiente signature de la app ─────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1C2D), Color(0xFF0F2744), Color(0xFF0D7490)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C4F0), Color(0xFF0891B2)],
  );

  // ── Semánticos ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
}