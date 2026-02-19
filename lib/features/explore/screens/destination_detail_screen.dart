// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/destination_model.dart';
import 'gallery_fullscreen_screen.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📸 Imagen principal con Hero
          Hero(
            tag: destination.id,
            child: SizedBox(
              height: 350,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    destination.mainImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 60),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${destination.city}, ${destination.country}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔙 Botón volver
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // 📄 Contenido principal
          Container(
            margin: const EdgeInsets.only(top: 300),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ⭐ Rating + precio + duración
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${destination.rating} (${destination.reviews} reseñas)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      // Precio estimado
                      if (destination.priceMin > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${destination.currency} ${destination.priceMin.toInt()} - ${destination.priceMax.toInt()}/noche',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🌤 Info rápida (clima, temporada, duración)
                  if (destination.climate.isNotEmpty ||
                      destination.bestSeason.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (destination.climate.isNotEmpty)
                            _InfoChip(
                              icon: Icons.wb_sunny_outlined,
                              label: 'Clima',
                              value: destination.climate,
                            ),
                          if (destination.bestSeason.isNotEmpty)
                            _InfoChip(
                              icon: Icons.calendar_month_outlined,
                              label: 'Mejor época',
                              value: destination.bestSeason,
                            ),
                          if (destination.durationMin > 0)
                            _InfoChip(
                              icon: Icons.schedule_outlined,
                              label: 'Duración',
                              value:
                                  '${destination.durationMin}-${destination.durationMax} días',
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 📝 Descripción
                  const Text(
                    'Descripción',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    destination.description,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),

                  const SizedBox(height: 24),

                  // 🏷 Tags
                  if (destination.tags.isNotEmpty) ...[
                    const Text(
                      'Tipo de destino',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: destination.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.08),
                                labelStyle: const TextStyle(
                                    color: AppColors.primary, fontSize: 13),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 🎯 Actividades reales (antes eran hardcodeadas)
                  if (destination.activities.isNotEmpty) ...[
                    const Text(
                      'Actividades disponibles',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...destination.activities
                        .map((activity) => BulletPoint(text: activity))
                        .toList(),
                    const SizedBox(height: 24),
                  ],

                  // 🖼 Galería
                  if (destination.gallery.isNotEmpty) ...[
                    const Text(
                      'Galería',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: destination.gallery.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GalleryFullscreenScreen(
                                      images: destination.gallery,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  destination.gallery[index], // ✅ fix aquí
                                  width: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // 🔥 Botón inferior con datos del destino
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text(
            'Planear viaje con IA',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          onPressed: () {
            // ✅ Pasa el destino al planificador
            Navigator.pushNamed(
              context,
              '/plan',
              arguments: destination,
            );
          },
        ),
      ),
    );
  }
}

/* ========================= */

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
