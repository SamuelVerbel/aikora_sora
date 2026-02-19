import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  /// Obtener perfil por userId
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  /// Sincronizar perfil después del login (el trigger ya creó el registro)
  /// Solo actualiza si los datos de Google son mejores que los actuales
  Future<void> syncProfileAfterLogin(User user) async {
    final metadata = user.userMetadata ?? {};
    final nameFromAuth = metadata['name'] ?? metadata['full_name'];
    final avatarFromAuth = metadata['avatar_url'] ?? metadata['picture'];

    // El trigger ya creó el perfil, solo verificamos si necesita actualización
    final profile = await getProfile(user.id);
    if (profile == null) return; // No debería pasar, pero es seguro

    final updates = <String, dynamic>{};

    // Actualiza nombre solo si era genérico
    if ((profile['full_name'] == 'Usuario' || profile['full_name'] == null)
        && nameFromAuth != null) {
      updates['full_name'] = nameFromAuth;
    }

    // Actualiza avatar si cambió
    if (avatarFromAuth != null && profile['avatar_url'] != avatarFromAuth) {
      updates['avatar_url'] = avatarFromAuth;
    }

    if (updates.isNotEmpty) {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
    }
  }

  /// Actualizar datos del perfil manualmente (desde ProfileScreen)
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? avatarUrl,
  }) async {
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
