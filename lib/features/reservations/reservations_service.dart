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
      print('Error cargando reservas: $e');
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
        .update({'status': 'cancelled'})
        .eq('id', reservationId);
  }
}
