import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_service.dart';

/// Servicio que encapsula todo lo relacionado con autenticación.
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Iniciar sesión con Google OAuth.
  Future<void> signInWithGoogle() async {
    try {
      final redirectUrl = kIsWeb
          ? Uri.base.origin
          : 'com.aikorasora.app://login-callback/';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      debugPrint('Error en Google OAuth: $e');
      rethrow;
    }
  }

  /// Sincronizar perfil tras cualquier login — llamar desde main.dart
  /// en el listener onAuthStateChange cuando el evento sea signedIn.
  static Future<void> syncAfterLogin(User user) async {
    try {
      await ProfileService().syncProfileAfterLogin(user);
    } catch (e) {
      debugPrint('Error sincronizando perfil: $e');
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