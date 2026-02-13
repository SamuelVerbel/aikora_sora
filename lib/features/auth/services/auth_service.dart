import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Iniciar sesión con Google (crea cuenta si no existe)
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.aikorasora.app://login-callback/',
      );
    } catch (e) {
      print('Error en Google OAuth: $e');
      rethrow;
    }
  }

  /// Iniciar sesión con email/contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      print('Error en login email: $e');
      rethrow;
    }
  }

  /// Registrar con email/contraseña
  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );
      return response.user;
    } catch (e) {
      print('Error en registro email: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Obtener usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  /// Verificar si hay sesión activa
  Future<Session?> getSession() async {
    return _supabase.auth.currentSession;
  }
}