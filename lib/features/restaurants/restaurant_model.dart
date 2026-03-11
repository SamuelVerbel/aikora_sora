/// Modelo de datos que representa un restaurante vinculado a un destino.
/// Se construye a partir del JSON que devuelve Supabase.
class Restaurant {
  final String id;
  final String destinationId;
  final String name;
  final String cuisine;
  final String priceRange;
  final double rating;
  final String imageUrl;
  final double latitude;
  final double longitude;

  // ⭐ NUEVO (Google Places)
  final bool isExternal; // viene de Google o DB
  final String? address;

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
    this.isExternal = false,
    this.address,
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
      isExternal: false,
      address: json['address'],
    );
  }
}
