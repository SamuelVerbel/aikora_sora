import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env.dart';
import 'restaurant_model.dart';

class RestaurantsService {
  final _supabase = Supabase.instance.client;
  final String _apiKey = Env.googleMapsApiKey;

  /// Busca restaurantes reales en Google Places usando coordenadas.
  /// Si falla o la key no está configurada, usa Supabase como respaldo.
  Future<List<Restaurant>> getRealTimeRestaurants({
    required double lat,
    required double lng,
    required String destinationId,
  }) async {
    // Si no hay key válida, usar Supabase directamente
    if (_apiKey.isEmpty || _apiKey == 'tu_key') {
      return getByDestination(destinationId);
    }

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

        // Si Google retorna error de key inválida, usar Supabase
        if (data['status'] == 'REQUEST_DENIED' ||
            data['status'] == 'INVALID_REQUEST') {
          debugPrint('Google Places key inválida, usando Supabase...');
          return getByDestination(destinationId);
        }

        final List results = data['results'] ?? [];
        if (results.isEmpty) return getByDestination(destinationId);

        // Deduplicar por place_id
        final seen = <String>{};
        final restaurants = <Restaurant>[];

        for (final place in results) {
          final placeId = place['place_id'] ?? '';
          if (placeId.isEmpty || seen.contains(placeId)) continue;
          seen.add(placeId);

          String photoUrl = '';
          if (place['photos'] != null &&
              (place['photos'] as List).isNotEmpty) {
            final photoRef = place['photos'][0]['photo_reference'];
            photoUrl =
                'https://maps.googleapis.com/maps/api/place/photo'
                '?maxwidth=400&photoreference=$photoRef&key=$_apiKey';
          }

          // Detectar tipo de cocina más específico
          final types = List<String>.from(place['types'] ?? []);
          String cuisine = 'Restaurante';
          if (types.contains('cafe')) cuisine = 'Café';
          else if (types.contains('bar')) cuisine = 'Bar';
          else if (types.contains('bakery')) cuisine = 'Panadería';
          else if (types.contains('meal_takeaway')) cuisine = 'Para llevar';

          restaurants.add(Restaurant(
            id: placeId,
            destinationId: destinationId,
            name: place['name'] ?? 'Restaurante',
            cuisine: cuisine,
            priceRange: _priceLevel(place['price_level']),
            rating: (place['rating'] ?? 0.0).toDouble(),
            imageUrl: photoUrl,
            latitude:
                (place['geometry']['location']['lat'] ?? 0).toDouble(),
            longitude:
                (place['geometry']['location']['lng'] ?? 0).toDouble(),
            isExternal: true,
            address: place['vicinity'] ?? '',
          ));
        }

        return restaurants;
      }

      return getByDestination(destinationId);
    } catch (e) {
      debugPrint('Error en Google Places: $e. Usando Supabase...');
      return getByDestination(destinationId);
    }
  }

  /// Convierte el nivel de precio numérico a símbolo de dólares
  String _priceLevel(dynamic level) {
    switch (level) {
      case 0: return 'free';
      case 1: return 'low';
      case 2: return 'mid';
      case 3: return 'high';
      case 4: return 'high';
      default: return 'mid';
    }
  }

  /// Restaurantes de Supabase por destino (respaldo).
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
      debugPrint('Error en Supabase restaurantes: $e');
      return [];
    }
  }

  /// Todos los restaurantes (modo general sin coordenadas).
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
      debugPrint('Error cargando todos los restaurantes: $e');
      return [];
    }
  }
}