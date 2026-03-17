import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env.dart'; // Importamos tu Env seguro
import 'restaurant_model.dart';

class RestaurantsService {
  final _supabase = Supabase.instance.client;
  final String _apiKey = Env.googleMapsApiKey;

  /// Busca restaurantes REALES en Google Places usando coordenadas.
  /// Ideal para la experiencia "tipo Rappi".
  Future<List<Restaurant>> getRealTimeRestaurants({
    required double lat,
    required double lng,
    required String destinationId,
  }) 
  
  async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=2000'
        '&type=restaurant'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        return results.map((place) {
          // Construcción de la foto real
          String photoUrl = 'https://via.placeholder.com/400x300?text=Aikora+Sora';
          if (place['photos'] != null && (place['photos'] as List).isNotEmpty) {
            final photoRef = place['photos'][0]['photo_reference'];
            photoUrl = 'https://maps.googleapis.com/maps/api/place/photo'
                '?maxwidth=400&photoreference=$photoRef&key=$_apiKey';
          }

          return Restaurant(
            id: place['place_id'] ?? '',
            destinationId: destinationId,
            name: place['name'] ?? 'Restaurante',
            cuisine: (place['types'] as List).contains('cafe')
                ? 'Café'
                : 'Restaurante',
            priceRange: (place['price_level'] ?? 2).toString(),
            rating: (place['rating'] ?? 0.0).toDouble(),
            imageUrl: photoUrl,
            latitude: (place['geometry']['location']['lat'] ?? 0).toDouble(),
            longitude: (place['geometry']['location']['lng'] ?? 0).toDouble(),

            // ⭐ NUEVO
            isExternal: true,
            address: place['vicinity'],
          );
        }).toList();
      }
      
      // Si Google falla, intentamos traer los de respaldo de Supabase
      return getByDestination(destinationId);
    } catch (e) {
      print('Error en Google Places: $e. Usando respaldo de Supabase...');
      return getByDestination(destinationId);
    }
  }

  /// Tu método original de Supabase (queda como respaldo)
  Future<List<Restaurant>> getByDestination(String destinationId) async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select()
          .eq('destination_id', destinationId)
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();
    } catch (e) {
      print('Error en Supabase: $e');
      return [];
    }
  }

  /// Obtiene TODOS los restaurantes desde Supabase.
  /// Se usa cuando no hay coordenadas (modo general).
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