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
  final double latitude;
  final double longitude;
  final String category;
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

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] ?? '',
      title: json['name'] ?? 'Sin nombre',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      description: json['description'] ?? '',
      mainImage: json['image_url'] ?? '',
      gallery: List<String>.from(json['gallery'] ?? []),
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
