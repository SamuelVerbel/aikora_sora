import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';

class TripRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> createTrip(Trip trip) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No autenticado');

    final response = await _supabase
        .from('trips')
        .insert({...trip.toMap(), 'user_id': userId})
        .select()
        .single();

    return response['id'] as String;
  }

  Future<List<Trip>> getUserTrips() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('trips')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((m) => Trip.fromMap(m)).toList();
    } catch (e) {
      debugPrint('TripRepository.getUserTrips error: $e');
      return [];
    }
  }

  Future<Trip?> getTripById(String id) async {
    try {
      final response =
          await _supabase.from('trips').select().eq('id', id).single();
      return Trip.fromMap(response);
    } catch (e) {
      debugPrint('TripRepository.getTripById error: $e');
      return null;
    }
  }

  Future<void> deleteTrip(String id) async {
    await _supabase.from('trips').delete().eq('id', id);
  }

  // ─── RF-20: Colaboración ──────────────────────────────────────────────────

  Future<void> inviteCollaborator({
    required String tripId,
    required String email,
  }) async {
    await _supabase.from('trip_collaborators').insert({
      'trip_id': tripId,
      'invited_email': email,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCollaborators(String tripId) async {
    try {
      final response = await _supabase
          .from('trip_collaborators')
          .select()
          .eq('trip_id', tripId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('TripRepository.getCollaborators error: $e');
      return [];
    }
  }

  /// RF-20 — Suscripción Realtime.
  /// Usa el canal genérico de Supabase compatible con v2.x
  RealtimeChannel subscribeToTrip({
    required String tripId,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    return _supabase
        .channel('trip_$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          // En supabase_flutter 2.x el filter es un String directo
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  Future<void> updateItinerary({
    required String tripId,
    required List<Map<String, dynamic>> itinerary,
  }) async {
    await _supabase.from('trips').update({
      'itinerary': itinerary,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tripId);
  }
}