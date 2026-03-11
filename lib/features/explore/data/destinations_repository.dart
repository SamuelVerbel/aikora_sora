import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/destination_model.dart';

/// Repositorio encargado de manejar todas las consultas
/// relacionadas con destinos turísticos.
///
/// Sigue el patrón **Repository Pattern** para separar
/// la lógica de acceso a datos de la interfaz de usuario.
class DestinationsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Cache local para evitar múltiples llamadas innecesarias a la base de datos.
  List<Destination>? _cachedDestinations;

  /// Obtiene todos los destinos disponibles.
  /// Si ya fueron cargados previamente, devuelve la versión en caché.
  Future<List<Destination>> getDestinations({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedDestinations != null) {
        return _cachedDestinations!;
      }

      final response = await _supabase
          .from('destinations')
          .select()
          .order('rating', ascending: false);

      final destinations = (response as List)
          .map((data) => Destination.fromJson(data))
          .toList();

      _cachedDestinations = destinations;

      return destinations;
    } catch (e) {
      debugPrint('Error cargando destinos: $e');
      return [];
    }
  }

  /// Obtiene un destino específico por su ID.
  Future<Destination?> getDestinationById(String id) async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .eq('id', id)
          .single();

      return Destination.fromJson(response);
    } catch (e) {
      debugPrint('Error obteniendo destino: $e');
      return null;
    }
  }

  /// Busca destinos por nombre, país o ciudad.
  Future<List<Destination>> searchDestinations(String query) async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .or('name.ilike.%$query%,country.ilike.%$query%,city.ilike.%$query%')
          .order('rating', ascending: false);

      return (response as List)
          .map((data) => Destination.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error buscando destinos: $e');
      return [];
    }
  }

  /// Obtiene destinos filtrados por categoría.
  Future<List<Destination>> getDestinationsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .eq('category', category)
          .order('rating', ascending: false);

      return (response as List)
          .map((data) => Destination.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error cargando destinos por categoría: $e');
      return [];
    }
  }

  /// Limpia el cache en memoria.
  /// Se puede usar si el usuario actualiza la información.
  void clearCache() {
    _cachedDestinations = null;
  }
}