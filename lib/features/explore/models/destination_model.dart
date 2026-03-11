/// Modelo de datos que representa un destino turístico dentro de la aplicación.
///
/// Este archivo funciona como una **Entity** dentro de la arquitectura del proyecto.
/// Convierte los datos crudos que vienen de Supabase (JSON) en un objeto Dart
/// fuertemente tipado que puede ser usado por toda la aplicación.

class Destination {
  final String id;
  final String title;
  final String country;
  final String city;
  final String description;
  final String mainImage;

  final List<String> gallery;

  final double rating;
  final int reviews;

  /// Coordenadas geográficas del destino
  final double latitude;
  final double longitude;

  /// Categoría turística (playa, montaña, cultura, ciudad, etc.)
  final String category;

  /// Servicios disponibles en el destino
  final List<String> amenities;

  /// Rango de precios estimado
  final double priceMin;
  final double priceMax;

  /// Moneda utilizada
  final String currency;

  /// Información climática
  final String climate;
  final String bestSeason;

  /// Actividades turísticas disponibles
  final List<String> activities;

  /// Tags utilizados para recomendaciones
  final List<String> tags;

  /// Duración recomendada del viaje (días)
  final int durationMin;
  final int durationMax;

  /// Distancia desde el usuario (calculada dinámicamente con GPS)
  /// No se guarda en base de datos.
  double? distanceFromUser;

  Destination({
    required this.id,
    required this.title,
    required this.country,
    required this.city,
    required this.description,
    required this.mainImage,
    required this.gallery,
    required this.rating,
    required this.reviews,
    required this.latitude,
    required this.longitude,
    this.category = 'general',
    this.amenities = const [],
    this.priceMin = 0,
    this.priceMax = 0,
    this.currency = 'USD',
    this.climate = '',
    this.bestSeason = '',
    this.activities = const [],
    this.tags = const [],
    this.durationMin = 3,
    this.durationMax = 7,
  });

  /// Crea una instancia del modelo a partir de JSON proveniente de Supabase
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] ?? '',
      title: json['name'] ?? 'Sin nombre',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      description: json['description'] ?? '',
      mainImage: json['image_url'] ?? '',

      gallery: (json['gallery'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [],

      rating: (json['rating'] ?? 0).toDouble(),
      reviews: (json['reviews'] ?? 0).toInt(),

      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),

      category: json['category'] ?? 'general',

      amenities: (json['amenities'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [],

      priceMin: (json['price_min'] ?? 0).toDouble(),
      priceMax: (json['price_max'] ?? 0).toDouble(),

      currency: json['currency'] ?? 'USD',

      climate: json['climate'] ?? '',
      bestSeason: json['best_season'] ?? '',

      activities: (json['activities'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [],

      tags: (json['tags'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [],

      durationMin: (json['duration_days_min'] ?? 3).toInt(),
      durationMax: (json['duration_days_max'] ?? 7).toInt(),
    );
  }

  /// Permite crear copias modificadas del objeto sin mutarlo.
  Destination copyWith({
    String? id,
    String? title,
    String? country,
    String? city,
    String? description,
    String? mainImage,
    List<String>? gallery,
    double? rating,
    int? reviews,
    double? latitude,
    double? longitude,
    String? category,
    List<String>? amenities,
    double? priceMin,
    double? priceMax,
    String? currency,
    String? climate,
    String? bestSeason,
    List<String>? activities,
    List<String>? tags,
    int? durationMin,
    int? durationMax,
  }) {
    return Destination(
      id: id ?? this.id,
      title: title ?? this.title,
      country: country ?? this.country,
      city: city ?? this.city,
      description: description ?? this.description,
      mainImage: mainImage ?? this.mainImage,
      gallery: gallery ?? this.gallery,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      amenities: amenities ?? this.amenities,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      currency: currency ?? this.currency,
      climate: climate ?? this.climate,
      bestSeason: bestSeason ?? this.bestSeason,
      activities: activities ?? this.activities,
      tags: tags ?? this.tags,
      durationMin: durationMin ?? this.durationMin,
      durationMax: durationMax ?? this.durationMax,
    );
  }

  /// Convierte el modelo nuevamente a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'country': country,
      'city': city,
      'description': description,
      'image_url': mainImage,
      'gallery': gallery,
      'rating': rating,
      'reviews': reviews,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'amenities': amenities,
      'price_min': priceMin,
      'price_max': priceMax,
      'currency': currency,
      'climate': climate,
      'best_season': bestSeason,
      'activities': activities,
      'tags': tags,
      'duration_days_min': durationMin,
      'duration_days_max': durationMax,
    };
  }

  /// Calcula un puntaje de popularidad basado en rating y número de reseñas.
  double get popularityScore {
    if (reviews == 0) return rating;
    return rating * (1 + (reviews / 100));
  }
}