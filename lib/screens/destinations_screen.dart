import 'package:flutter/material.dart';
import '../features/destinations/models/destination_model.dart';

class DestinationsScreen extends StatelessWidget {
  const DestinationsScreen({super.key});

  static final List<Destination> destinations = [
    Destination(
      id: '1',
      name: 'Cartagena',
      country: 'Colombia',
      description: 'Ciudad histórica con playas y cultura.',
      latitude: 10.3910,
      longitude: -75.4794,
      tags: ['cultura', 'playa'],
    ),
    Destination(
      id: '2',
      name: 'Medellín',
      country: 'Colombia',
      description: 'Ciudad de innovación y clima primaveral.',
      latitude: 6.2442,
      longitude: -75.5812,
      tags: ['naturaleza', 'ciudad'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destinos'),
      ),
      body: ListView.builder(
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final destination = destinations[index];
          return ListTile(
            leading: const Icon(Icons.place),
            title: Text(destination.name),
            subtitle: Text(destination.country),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Luego abriremos el detalle
            },
          );
        },
      ),
    );
  }
}
