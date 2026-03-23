import '../explore/models/destination_model.dart';
import 'user_behavior_service.dart';
import '../explore/data/destinations_repository.dart';

class RecommendationEngine {
  final UserBehaviorService _behavior = UserBehaviorService();

  Future<List<Destination>> rankDestinations(
    List<Destination> destinations) async {

    final viewed = await _behavior.getViewedDestinations();
    final preferredType = await _behavior.getPreference('travel_type');

    final ranked = List<Destination>.from(destinations);

    ranked.sort((a, b) {
      double scoreA = _score(a, viewed, preferredType);
      double scoreB = _score(b, viewed, preferredType);
      return scoreB.compareTo(scoreA);
    });

    return ranked;
  }

  double _score(
    Destination d,
    List<String> viewed,
    String? preferredType,
  ) {
    double score = 0;

    // ⭐ ya visto = interés
    if (viewed.contains(d.id)) {
      score += 3;
    }

    // ⭐ coincide con preferencia
    if (preferredType != null && d.category.toLowerCase() == preferredType.toLowerCase()) {
      score += 5;
    }

    // ⭐ rating alto
    score += d.rating;


    return score;
  }

  Future<List<Destination>> getTopRecommendations(
    List<Destination> destinations, {
    int limit = 5,
  }) 
  
  async {
    final ranked = await rankDestinations(destinations);

    if (ranked.isEmpty) return [];

    return ranked.take(limit).toList();
  }

  /// 🧠 Detecta la categoría favorita del usuario
  Future<String?> getUserPreferredCategory() async {
    final behavior = UserBehaviorService();
    final repository = DestinationsRepository();

    // IDs vistos por el usuario
    final viewedIds = await behavior.getViewedDestinations();

    if (viewedIds.isEmpty) return null;

    // Obtener destinos reales desde BD/cache
    final allDestinations = await repository.getDestinations();

    final Map<String, int> counter = {};

    for (final dest in allDestinations) {
      if (viewedIds.contains(dest.id)) {
        final category = dest.category;

        counter[category] = (counter[category] ?? 0) + 1;
      }
    }

    // encontrar categoría dominante
    String? topCategory;
    int max = 0;

    counter.forEach((key, value) {
      if (value > max) {
        max = value;
        topCategory = key;
      }
    });

    return topCategory;
  }
}