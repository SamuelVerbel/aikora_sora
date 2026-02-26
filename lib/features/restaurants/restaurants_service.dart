import 'package:supabase_flutter/supabase_flutter.dart';
import 'restaurant_model.dart';

/// Servicio que encapsula todas las llamadas a Supabase
/// relacionadas con la tabla 'restaurants'.
class RestaurantsService {
  // Cliente de Supabase (ya inicializado en main.dart)
  final _supabase = Supabase.instance.client;

  /// Trae solo los restaurantes de un destino específico.
  /// Se usa cuando el usuario entra al detalle de un destino.
  /// Ordenados de mayor a menor rating.
  Future<List<Restaurant>> getByDestination(String destinationId) async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select()
          .eq('destination_id', destinationId)  // Filtra por destino
          .order('rating', ascending: false);    // Mejor calificados primero

      return (response as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();
    } catch (e) {
      // Si falla la conexión, devolvemos lista vacía para no romper la UI
      print('Error cargando restaurantes por destino: $e');
      return [];
    }
  }

  /// Trae TODOS los restaurantes de la base de datos.
  /// Se usa en la pantalla general de restaurantes.
  Future<List<Restaurant>> getAll() async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select()
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();
    } catch (e) {
      print('Error cargando todos los restaurantes: $e');
      return [];
    }
  }
}
