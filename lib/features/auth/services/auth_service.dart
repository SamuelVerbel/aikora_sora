import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio que encapsula todo lo relacionado con autenticación.
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Iniciar sesión con Google OAuth.
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? null
            : 'com.aikorasora.app://login-callback/',
      );
    } catch (e) {
      debugPrint('Error en Google OAuth: $e');
      rethrow;
    }
  }

  /// Iniciar sesión con email y contraseña.
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      debugPrint('Error en login email: $e');
      rethrow;
    }
  }

  /// Registrar nuevo usuario con email/contraseña.
  Future<User?> signUpWithEmail(
      String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      return response.user;
    } catch (e) {
      debugPrint('Error en registro email: $e');
      rethrow;
    }
  }

  /// Cerrar sesión.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<Session?> getSession() async => _supabase.auth.currentSession;
}