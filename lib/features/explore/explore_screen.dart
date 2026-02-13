import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../explore/models/destination_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String query = '';

  final List<Destination> destinations = [
    Destination(
      title: 'Cartagena de Indias',
      country: 'Colombia',
      description: 'Historia, playas y cultura',
      imageUrl: 'https://source.unsplash.com/featured/?cartagena,beach,city',
    ),
    Destination(
      title: 'Kyoto',
      country: 'Japón',
      description: 'Templos, tradición y naturaleza',
      imageUrl: 'https://source.unsplash.com/featured/?kyoto,japan,temple',
    ),
    Destination(
      title: 'París',
      country: 'Francia',
      description: 'Arte, gastronomía y romance',
      imageUrl: 'https://source.unsplash.com/featured/?paris,eiffel',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDestinations = destinations.where((d) {
      return d.title.toLowerCase().contains(query.toLowerCase()) ||
          d.country.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar destinos'),
      ),
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar destino o país',
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
              destination.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 40,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                  destination.country,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(destination.description),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
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