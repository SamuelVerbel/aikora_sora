import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './../explore/models/destination_model.dart';

/// Servicio de administración de Aikōra Sora.
/// Solo accesible para usuarios con role = 'admin' en la tabla profiles.
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache para estadísticas
  Map<String, dynamic>? _statsCache;
  DateTime? _statsCacheTime;
  static const _statsCacheDuration = Duration(seconds: 30);
  
  // Rate limiting
  final Map<String, DateTime> _lastDestructiveAction = {};
  static const _destructiveActionCooldown = Duration(seconds: 3);

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

  // ─── Dashboard stats con cache ───────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _statsCache != null &&
        _statsCacheTime != null &&
        DateTime.now().difference(_statsCacheTime!) < _statsCacheDuration) {
      return _statsCache!;
    }

    try {
      final destinationsCount =
          (await _supabase.from('destinations').select('id') as List).length;

      final usersCount =
          (await _supabase.from('profiles').select('id') as List).length;

      final reservationsCount =
          (await _supabase.from('reservations').select('id') as List).length;

      final pendingCount =
          (await _supabase
                  .from('reservations')
                  .select('id')
                  .eq('status', 'pending') as List)
              .length;

      _statsCache = {
        'total_destinations': destinationsCount,
        'total_users': usersCount,
        'total_reservations': reservationsCount,
        'pending_reservations': pendingCount,
      };

      _statsCacheTime = DateTime.now();
      return _statsCache!;
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
    _invalidateCache();
  }

  Future<void> updateDestination(Destination destination) async {
    await _supabase
        .from('destinations')
        .update(destination.toJson())
        .eq('id', destination.id);
    _invalidateCache();
  }

  Future<void> deleteDestination(String id) async {
    if (!_canPerformAction('delete_destination_$id')) {
      throw Exception('Espera unos segundos antes de eliminar otro destino');
    }
    await _supabase.from('destinations').delete().eq('id', id);
    _invalidateCache();
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
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == userId) {
      throw Exception('No puedes cambiar tu propio rol');
    }
    await _supabase
        .from('profiles')
        .update({'role': role}).eq('id', userId);
  }

  Future<void> deleteUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == userId) {
      throw Exception('No puedes eliminar tu propia cuenta');
    }
    if (!_canPerformAction('delete_user_$userId')) {
      throw Exception('Espera unos segundos antes de eliminar otro usuario');
    }
    await _supabase.from('profiles').delete().eq('id', userId);
    _invalidateCache();
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

  // ─── Métodos privados ─────────────────────────────────────────────────────

  void _invalidateCache() {
    _statsCache = null;
    _statsCacheTime = null;
  }

  bool _canPerformAction(String key) {
    final last = _lastDestructiveAction[key];
    if (last != null && DateTime.now().difference(last) < _destructiveActionCooldown) {
      return false;
    }
    _lastDestructiveAction[key] = DateTime.now();
    return true;
  }
}