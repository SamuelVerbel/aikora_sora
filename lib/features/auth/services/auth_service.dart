import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio que encapsula todo lo relacionado con autenticación.
/// Así no llamas a Supabase directamente desde los widgets.
class AuthService {

  // Cliente principal de Supabase (ya inicializado en main.dart)
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Iniciar sesión con Google (en móvil abre Custom Tabs / navegador).
  /// - Si el usuario no existe, Supabase crea la cuenta.
  /// - Si ya existe, solo hace login.
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Esquema de redirección configurado en android/ios (deep link)
        redirectTo: 'com.aikorasora.app://login-callback/',
      );
    } catch (e) {
      // Imprime el error en consola para depurar
      print('Error en Google OAuth: $e');
      // rethrow = vuelve a lanzar la excepción para que la capa UI la maneje
      rethrow;
    }
  }

  /// Iniciar sesión con email/contraseña.
  /// Devuelve el User autenticado si todo sale bien.
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

  /// Registrar nuevo usuario con email/contraseña.
  /// Además, envía `name` como metadata para que el trigger de Supabase
  /// pueda usarlo al crear el registro en la tabla `profiles`.
  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name, // metadata (user.userMetadata['name'])
        },
      );
      return response.user;
    } catch (e) {
      print('Error en registro email: $e');
      rethrow;
    }
  }

  /// Cerrar sesión en Supabase.
  /// Limpia la sesión actual en el dispositivo.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Acceso rápido al usuario autenticado (puede ser null).
  User? get currentUser => _supabase.auth.currentUser;

  /// Obtener la sesión activa (incluye tokens, expiración, etc.).
  /// Útil si quieres revisar info extra, aunque normalmente con `currentUser` es suficiente.
  Future<Session?> getSession() async {
    return _supabase.auth.currentSession;
  }
}