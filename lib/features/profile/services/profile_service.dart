import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  Future<void> createProfile(
      String userId,
      String email,
      String name,
    ) async {
      await _client.from('profiles').insert({
        'id': userId,
        'email': email,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
}
