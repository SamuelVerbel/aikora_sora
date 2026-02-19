import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/destination_model.dart';

class DestinationsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener todos los destinos desde Supabase
  Future<List<Destination>> getDestinations() async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .order('created_at');

      return (response as List)
          .map((data) => Destination.fromJson(data))
          .toList();
    } catch (e) {
      print('Error cargando destinos: $e');
      return [];
    }
  }

  // Buscar destinos por nombre o país
  Future<List<Destination>> searchDestinations(String query) async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .or('name.ilike.%$query%,country.ilike.%$query%,city.ilike.%$query%');

      return (response as List)
          .map((data) => Destination.fromJson(data))
          .toList();
    } catch (e) {
      print('Error buscando destinos: $e');
      return [];
    }
  }
}
