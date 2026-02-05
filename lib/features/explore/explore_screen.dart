import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar destinos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          DestinationCard(
            title: 'Cartagena de Indias',
            country: 'Colombia',
            description: 'Historia, playas y cultura',
            imageUrl: 'https://picsum.photos/400/200?1',
          ),
          DestinationCard(
            title: 'Kyoto',
            country: 'Japón',
            description: 'Templos, tradición y naturaleza',
            imageUrl: 'https://picsum.photos/400/200?2',
          ),
          DestinationCard(
            title: 'París',
            country: 'Francia',
            description: 'Arte, gastronomía y romance',
            imageUrl: 'https://picsum.photos/400/200?3',
          ),
        ],
      ),
    );
  }
}

class DestinationCard extends StatelessWidget {
  final String title;
  final String country;
  final String description;
  final String imageUrl;

  const DestinationCard({
    super.key,
    required this.title,
    required this.country,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  country,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(description),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: () {
                    // luego abrimos detalle del destino
                  },
                  child: const Text('Ver más'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
