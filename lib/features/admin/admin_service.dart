import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './../explore/models/destination_model.dart';

/// Servicio de administración de Aikōra Sora.
/// Solo accesible para usuarios con role = 'admin' en la tabla profiles.
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Control de acceso ────────────────────────────────────────────────────

  /// Verifica si el usuario actual tiene rol de admin.
  Future<bool> isAdmin() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return response?['role'] == 'admin';
    } catch (e) {
      debugPrint('AdminService.isAdmin error: $e');
      return false;
    }
  }

  // ─── Dashboard stats ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final results = await Future.wait([
        _supabase.from('destinations').select('id').count(),
        _supabase.from('profiles').select('id').count(),
        _supabase.from('reservations').select('id').count(),
        _supabase
            .from('reservations')
            .select('id')
            .eq('status', 'pending')
            .count(),
      ]);

      return {
        'total_destinations': (results[0] as PostgrestResponse).count ?? 0,
        'total_users': (results[1] as PostgrestResponse).count ?? 0,
        'total_reservations': (results[2] as PostgrestResponse).count ?? 0,
        'pending_reservations': (results[3] as PostgrestResponse).count ?? 0,
      };
    } catch (e) {
      debugPrint('AdminService.getDashboardStats error: $e');
      return {
        'total_destinations': 0,
        'total_users': 0,
        'total_reservations': 0,
        'pending_reservations': 0,
      };
    }
  }

  // ─── Gestión de destinos ──────────────────────────────────────────────────

  Future<List<Destination>> getAllDestinations() async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((d) => Destination.fromJson(d))
          .toList();
    } catch (e) {
      debugPrint('AdminService.getAllDestinations error: $e');
      return [];
    }
  }

  Future<void> createDestination(Destination destination) async {
    final json = destination.toJson()..remove('id');
    await _supabase.from('destinations').insert(json);
  }

  Future<void> updateDestination(Destination destination) async {
    await _supabase
        .from('destinations')
        .update(destination.toJson())
        .eq('id', destination.id);
  }

  Future<void> deleteDestination(String id) async {
    await _supabase.from('destinations').delete().eq('id', id);
  }

  // ─── Gestión de usuarios ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, email, role, created_at, avatar_url')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService.getAllUsers error: $e');
      return [];
    }
  }

  Future<void> setUserRole(String userId, String role) async {
    await _supabase
        .from('profiles')
        .update({'role': role}).eq('id', userId);
  }

  Future<void> deleteUser(String userId) async {
    // Elimina perfil — el trigger de Supabase limpia el resto
    await _supabase.from('profiles').delete().eq('id', userId);
  }

  // ─── Gestión de reservas ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllReservations() async {
    try {
      final response = await _supabase
          .from('reservations')
          .select('*, destinations(name, city), profiles(full_name, email)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService.getAllReservations error: $e');
      return [];
    }
  }

  Future<void> updateReservationStatus(String id, String status) async {
    await _supabase
        .from('reservations')
        .update({'status': status}).eq('id', id);
  }
}