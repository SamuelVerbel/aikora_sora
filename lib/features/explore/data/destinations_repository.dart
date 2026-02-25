import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/destination_model.dart';

/// Repositorio de Destinos.
/// Se encarga EXCLUSIVAMENTE de comunicarse con la base de datos (Supabase).
/// Así separamos la lógica de negocio/datos de las pantallas (UI).
class DestinationsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todos los destinos disponibles en la tabla `destinations`.
  /// Se usa principalmente en la pantalla "ExploreScreen" inicial.
  Future<List<Destination>> getDestinations() async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .order('created_at'); // Ordenados del más antiguo al más nuevo

      // Transformamos la respuesta cruda de Supabase (List) a una lista
      // de objetos Destination usando el método fromJson() de nuestro modelo.
      return (response as List)
          .map((data) => Destination.fromJson(data))
          .toList();
    } catch (e) {
      print('Error cargando destinos: $e');
      // En caso de error (sin internet, BD caída), devolvemos lista vacía para que la app no haga crash.
      return [];
    }
  }

  /// Busca destinos por coincidencia en nombre, país o ciudad.
  /// (Nota: Aunque esta función existe, en "ExploreScreen" actualmente estamos
  /// haciendo el filtrado localmente en memoria para evitar tantas llamadas a la BD).
  Future<List<Destination>> searchDestinations(String query) async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          // "ilike" significa búsqueda "case-insensitive" (no importa mayúsculas).
          // El "%" es un comodín (busca la palabra en cualquier parte del texto).
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
