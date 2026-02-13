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
  });
}