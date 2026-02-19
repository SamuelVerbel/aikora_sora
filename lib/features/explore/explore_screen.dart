import 'package:flutter/material.dart';
import '../explore/models/destination_model.dart';
import '../explore/data/destinations_repository.dart';
import '../../core/routes/app_routes.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repository = DestinationsRepository();
  List<Destination> _allDestinations = [];
  List<Destination> _filtered = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final data = await _repository.getDestinations();
    if (mounted) {
      setState(() {
        _allDestinations = data;
        _filtered = data;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    setState(() {
      _query = value;
      _filtered = _allDestinations.where((d) {
        return d.title.toLowerCase().contains(_query.toLowerCase()) ||
            d.country.toLowerCase().contains(_query.toLowerCase()) ||
            d.city.toLowerCase().contains(_query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar destinos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar ciudad o país',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: _onSearch,
            ),
          ),

          // 📄 Contenido
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron destinos 😕',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDestinations, // Pull to refresh
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            return DestinationCard(
                              destination: _filtered[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   CARD DE DESTINO
========================= */
class DestinationCard extends StatelessWidget {
  final Destination destination;

  const DestinationCard({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📸 Imagen con Hero animation
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Hero(
              tag: destination.id,
              child: Image.network(
                destination.mainImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
          ),

          // 📄 Info
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${destination.city}, ${destination.country}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  destination.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${destination.rating} (${destination.reviews} reseñas)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.destinationDetail,
                        arguments: destination,
                      );
                    },
                    child: const Text('Ver más'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
