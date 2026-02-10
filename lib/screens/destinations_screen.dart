import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../features/explore/models/destination_model.dart';
import '../screens/destination_detail_screen.dart';


class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static final List<Destination> destinations = [
    Destination(
    title: 'Cartagena de Indias',
    country: 'Colombia',
    description: 'Historia, playas y cultura',
    imageUrl:
        'https://source.unsplash.com/featured/?cartagena,beach,city',
    ),
    Destination(
      title: 'Kyoto',
      country: 'Japón',
      description: 'Templos, tradición y naturaleza',
      imageUrl:
          'https://source.unsplash.com/featured/?kyoto,japan,temple',
    ),
    Destination(
      title: 'París',
      country: 'Francia',
      description: 'Arte, gastronomía y romance',
      imageUrl:
          'https://source.unsplash.com/featured/?paris,eiffel',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar destinos'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          return DestinationCard(destination: destinations[index]);
        },
      ),
    );
  }
}


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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DestinationDetailScreen(
                            destination: destination,
                          ),
                        ),
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
