class Destination {
  final String id;
  final String name;
  final String country;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> tags;

  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.tags,
  });
}
