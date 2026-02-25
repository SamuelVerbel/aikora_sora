
/// Clase modelo (Entity) que representa un Destino turístico en la aplicación.
/// Este archivo actúa como un "molde": toma los datos crudos que vienen de
/// Supabase (formato JSON) y los convierte en un objeto Dart fuertemente tipado.

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
  final double latitude; // Para ordenar por geolocalización
  final double longitude;
  final String category; // Ej: "playa", "cultura" (para los filtros)
  final List<String> amenities;
  final double priceMin;
  final double priceMax;
  final String currency;
  final String climate;
  final String bestSeason;
  final List<String> activities;
  final List<String> tags;
  final int durationMin;
  final int durationMax;

  /// Constructor principal.
  /// Algunos campos son `required` porque la app se rompería sin ellos (ej. id, título).
  /// Otros tienen valores por defecto (`this.category = 'general'`) por si en la base de datos están vacíos.
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

  /// Factory constructor: `fromJson`.
  /// Supabase nos devuelve un `Map<String, dynamic>`. Esta función mapea
  /// las llaves de la base de datos a las propiedades de nuestra clase en Dart.
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      // Se usa `??` para proveer un valor fallback (por defecto) si el dato es null.
      id: json['id'] ?? '',
      title: json['name'] ?? 'Sin nombre', // en DB se llama 'name', en app 'title'
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      description: json['description'] ?? '',
      mainImage: json['image_url'] ?? '',

      // List<String>.from convierte arreglos genéricos JSON en listas tipadas de Dart
      gallery: List<String>.from(json['gallery'] ?? []),
      
      // Se hace .toDouble() o .toInt() para evitar errores si Supabase 
      // manda un int en vez de un double, o viceversa.
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: (json['reviews'] ?? 0).toInt(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      category: json['category'] ?? 'general',
      amenities: List<String>.from(json['amenities'] ?? []),
      priceMin: (json['price_min'] ?? 0).toDouble(),
      priceMax: (json['price_max'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      climate: json['climate'] ?? '',
      bestSeason: json['best_season'] ?? '',
      activities: List<String>.from(json['activities'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      durationMin: (json['duration_days_min'] ?? 3).toInt(),
      durationMax: (json['duration_days_max'] ?? 7).toInt(),
    );
  }
}
