/// Modelo de datos que representa un restaurante vinculado a un destino.
/// Se construye a partir del JSON que devuelve Supabase.
class Restaurant {
  final String id;
  final String destinationId; // ID del destino al que pertenece
  final String name;
  final String cuisine;       // Tipo de cocina: italiana, colombiana, etc.
  final String priceRange;    // 'low' | 'mid' | 'high'
  final double rating;
  final String imageUrl;
  final double latitude;
  final double longitude;

  Restaurant({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.cuisine,
    required this.priceRange,
    required this.rating,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  /// Convierte el Map de Supabase en un objeto Restaurant.
  /// Los operadores ?? evitan errores si algún campo viene null.
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      destinationId: json['destination_id'] ?? '',
      name: json['name'] ?? '',
      cuisine: json['cuisine'] ?? '',
      priceRange: json['price_range'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}
