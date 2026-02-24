import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para leer y actualizar la tabla `profiles` en Supabase.
/// Aquí NO se maneja auth, solo datos de perfil.
class ProfileService {
  final _supabase = Supabase.instance.client;

  /// Obtener el registro de perfil de un usuario por su `userId`.
  /// Devuelve un Map con las columnas de la tabla o null si no existe.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return await _supabase
        .from('profiles')
        .select()
        .eq('id', userId) // columna id en la tabla `profiles`
        .maybeSingle(); // devuelve 0 o 1 registro (no lanza error si 0)
  }

  /// Sincronizar perfil después del login.
  /// - El trigger en Supabase ya se encargó de crear un perfil básico.
  /// - Aquí solo mejoramos los datos usando la metadata que trae Supabase Auth
  ///   (ej: nombre y foto de Google).
  Future<void> syncProfileAfterLogin(User user) async {

    // Metadata viene del proveedor de identidad (Google, email, etc.)
    final metadata = user.userMetadata ?? {};

    // Intentamos sacar un nombre razonable (depende del provider)
    final nameFromAuth = metadata['name'] ?? metadata['full_name'];

    // Intentamos sacar la URL del avatar (Google la expone como picture)
    final avatarFromAuth = metadata['avatar_url'] ?? metadata['picture'];

    // Buscamos el perfil ya creado por el trigger
    final profile = await getProfile(user.id);
    if (profile == null) return; // Si no hay perfil, salimos (no debería pasar)

    // Mapa de campos que queremos actualizar
    final updates = <String, dynamic>{};

    // Si el nombre actual en BD es "Usuario" o null, lo reemplazamos por el de Google
    if ((profile['full_name'] == 'Usuario' || profile['full_name'] == null)
        && nameFromAuth != null) {
      updates['full_name'] = nameFromAuth;
    }

    // Si hay un avatar nuevo y es diferente al almacenado, lo actualizamos
    if (avatarFromAuth != null && profile['avatar_url'] != avatarFromAuth) {
      updates['avatar_url'] = avatarFromAuth;
    }

    if (updates.isNotEmpty) {

      // Marcamos fecha de actualización
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      // Ejecutamos el update en la fila del usuario
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
    }
  }

  /// Actualizar datos del perfil de forma manual (desde ProfileScreen).
  ///
  /// Solo actualiza los campos que no vienen null.
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? avatarUrl,
  }) async {
    // Construimos dinámicamente el mapa de updates
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (fullName != null) 'full_name': fullName,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }
}
