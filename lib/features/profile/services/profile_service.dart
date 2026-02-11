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

  /// Crear perfil o actualizarlo si viene de Google
  Future<void> createOrUpdateProfile(User user) async {
    final metadata = user.userMetadata ?? {};
    final nameFromAuth = metadata['name'] ?? metadata['full_name'];
    final avatarFromAuth = metadata['avatar_url'] ?? metadata['picture'];

    final profile = await getProfile(user.id);

    if (profile == null) {
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'name': nameFromAuth ?? 'Viajero',
        'avatar': avatarFromAuth,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Actualiza solo si antes era genérico
      final updates = <String, dynamic>{};
      if (profile['name'] == 'Viajero' && nameFromAuth != null) {
        updates['name'] = nameFromAuth;
      }
      if (avatarFromAuth != null && profile['avatar'] != avatarFromAuth) {
        updates['avatar'] = avatarFromAuth;
      }

      if (updates.isNotEmpty) {
        await _supabase.from('profiles')
            .update(updates)
            .eq('id', user.id);
      }
    }
  }
}
