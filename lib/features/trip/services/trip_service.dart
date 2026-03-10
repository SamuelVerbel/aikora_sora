import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';

class TripService {
  final _client = Supabase.instance.client;

  Future<String> createTrip(Trip trip) async {
    final response = await _client
        .from('trips')
        .insert(trip.toMap())
        .select()
        .single();

    return response['id'];
  }
}