import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../explore/models/destination_model.dart';
import '../explore/data/destinations_repository.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String query = '';

  // 🔥 Ahora vienen del Repository (NO hardcode aquí)
  final List<Destination> destinations =
      DestinationsRepository.destinations;

  @override
  Widget build(BuildContext context) {
    final filteredDestinations = destinations.where((d) {
      return d.title.toLowerCase().contains(query.toLowerCase()) ||
          d.country.toLowerCase().contains(query.toLowerCase()) ||
          d.city.toLowerCase().contains(query.toLowerCase());
    }).toList();

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
              onChanged: (value) {
                setState(() => query = value);
              },
            ),
          ),

          // 📄 Lista / Estado vacío
          Expanded(
            child: filteredDestinations.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron destinos 😕',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDestinations.length,
                    itemBuilder: (context, index) {
                      final destination = filteredDestinations[index];
                      return DestinationCard(destination: destination);
                    },
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

  const DestinationCard({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📸 Imagen principal
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
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
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          // 📄 Información
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
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  destination.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // ⭐ Rating real
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
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/destination-detail',
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