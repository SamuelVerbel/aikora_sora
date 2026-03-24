import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para leer y actualizar la tabla `profiles` en Supabase.
/// Aquí NO se maneja auth, solo datos de perfil.
class ProfileService {
  final _supabase = Supabase.instance.client;

  /// Obtener el registro de perfil de un usuario por su `userId`.
  /// Devuelve un Map con las columnas de la tabla o null si no existe.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      return await _supabase
          .from('profiles')
          .select()
          .eq('id', userId) // columna id en la tabla `profiles`
          .maybeSingle(); // devuelve 0 o 1 registro (no lanza error si 0)
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
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
    try {
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
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // ==================== NUEVOS MÉTODOS PARA AVATAR ====================

  /// Subir imagen de avatar a Supabase Storage
  /// Retorna la URL pública de la imagen subida
  Future<String?> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '$userId/avatar_$timestamp.$fileExtension';
      
      print('Uploading avatar: $fileName'); // Debug

      // Subir a Supabase Storage
      await _supabase.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true, // Sobrescribe si existe
        ),
      );
      
      // Obtener URL pública
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      
      print('Avatar uploaded successfully: $publicUrl'); // Debug
      
      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  /// Eliminar avatar anterior (opcional, para limpiar storage)
  Future<bool> deleteOldAvatar({
    required String userId,
    String? oldAvatarUrl,
  }) async {
    if (oldAvatarUrl == null) return true;
    
    try {
      // Extraer el path del archivo desde la URL
      // URL ejemplo: https://project.supabase.co/storage/v1/object/public/avatars/userId/avatar_123.jpg
      final uri = Uri.parse(oldAvatarUrl);
      final pathSegments = uri.pathSegments;
      
      // Buscar el índice de 'avatars' en los segmentos
      final avatarsIndex = pathSegments.indexOf('avatars');
      if (avatarsIndex != -1 && avatarsIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(avatarsIndex + 1).join('/');
        
        await _supabase.storage.from('avatars').remove([filePath]);
        print('Old avatar deleted: $filePath');
      }
      
      return true;
    } catch (e) {
      print('Error deleting old avatar: $e');
      return false;
    }
  }

  /// Método combinado: subir nuevo avatar y actualizar perfil
  Future<bool> updateAvatarWithFile({
    required String userId,
    required File imageFile,
    String? oldAvatarUrl,
  }) async {
    try {
      // 1. Subir nueva imagen
      final newAvatarUrl = await uploadAvatar(
        userId: userId,
        imageFile: imageFile,
      );
      
      if (newAvatarUrl == null) return false;
      
      // 2. Actualizar perfil con la nueva URL
      await updateProfile(
        userId: userId,
        avatarUrl: newAvatarUrl,
      );
      
      // 3. Eliminar avatar anterior (opcional, para no acumular)
      await deleteOldAvatar(
        userId: userId,
        oldAvatarUrl: oldAvatarUrl,
      );
      
      return true;
    } catch (e) {
      print('Error in updateAvatarWithFile: $e');
      return false;
    }
  }

  /// Obtener URL de avatar de manera segura
  String? getAvatarUrl(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    
    final avatarUrl = profile['avatar_url'];
    if (avatarUrl == null || avatarUrl.toString().isEmpty) return null;
    
    // Validar que sea una URL válida de imagen
    final url = avatarUrl.toString();
    if (url.startsWith('http') && 
        (url.contains('.jpg') || 
         url.contains('.png') || 
         url.contains('.jpeg') || 
         url.contains('.webp') ||
         url.contains('supabase.co/storage'))) {
      return url;
    }
    
    return null;
  }
}