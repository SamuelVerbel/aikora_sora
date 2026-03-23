import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationsService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUserReservations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('reservations')
          .select('*, destinations(name, image_url, city, country)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error cargando reservas: $e');
      return [];
    }
  }

  Future<void> createReservation({
    required String destinationId,
    required DateTime startDate,
    required DateTime endDate,
    required int travelers,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No autenticado');

    await _supabase.from('reservations').insert({
      'user_id': userId,
      'destination_id': destinationId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'travelers': travelers,
      'notes': notes,
      'status': 'pending',
    });
  }

  Future<void> cancelReservation(String reservationId) async {
    await _supabase
        .from('reservations')
        .update({'status': 'cancelled'}).eq('id', reservationId);
  }

  /// Genera un plan de viaje usando la Edge Function de Supabase.
  /// Si falla, el caller debe manejar el error.
  Future<Map<String, dynamic>> generateAIPlan(
    Map<String, dynamic> args,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'generate-trip-plan',
        body: {
          'destination_name': args['destination_name'],
          'city': args['city'],
          'country': args['country'],
          'budget': args['budget'],
          'type': args['type'],
          'travelers': args['travelers'],
          'activities': args['activities'],
          'start_date': args['start_date']?.toString(),
          'end_date': args['end_date']?.toString(),
        },
      );

      if (response.data == null) throw Exception('Respuesta IA vacía');

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('Error llamando IA: $e');
      rethrow;
    }
  }
}