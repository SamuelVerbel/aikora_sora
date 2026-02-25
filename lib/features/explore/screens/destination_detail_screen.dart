// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/destination_model.dart';
import 'gallery_fullscreen_screen.dart';

/// Pantalla que muestra todos los detalles de un destino específico.
/// Recibe el objeto `Destination` completo a través de los argumentos de la ruta.
class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos Stack para que la imagen quede de fondo y el contenido blanco se solape encima
      body: Stack(
        children: [
          // ── 📸 Imagen Principal con efecto Hero ───────────────────────────
          // Hero permite que la imagen viaje suavemente desde la lista anterior hasta aquí.
          // El 'tag' debe ser exactamente igual en ambas pantallas (usamos el ID del destino).
          Hero(
            tag: destination.id,
            child: SizedBox(
              height: 350, // Ocupa un poco más del tercio superior de la pantalla
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen cargada de la URL
                  Image.network(
                    destination.mainImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 60),
                    ),
                  ),
                  // Sombra negra en la parte inferior para que las letras blancas se lean bien
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  // Título grande y País posicionados sobre la imagen
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

          // ── 🔙 Botón Volver Flotante ──────────────────────────────────────
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

          // ── 📄 Contenido Blanco Deslizable (La información) ──────────────
          Container(
            // El margen superior (300) hace que se vea un pedazo de la imagen principal
            margin: const EdgeInsets.only(top: 300),
            decoration: const BoxDecoration(
              color: Colors.white,
              // Borde redondeado superior para darle un look de "tarjeta superpuesta"
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ⭐ Fila 1: Rating y Rango de Precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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

                  // 🌤 Fila 2: Chips con info rápida (Clima, Temporada, Días recomendados)
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

                  // 📝 Fila 3: Descripción de texto largo
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

                  // 🏷 Fila 4: Etiquetas (Tags) de estilo de viaje
                  if (destination.tags.isNotEmpty) ...[
                    const Text(
                      'Tipo de destino',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,    // espacio horizontal entre chips
                      runSpacing: 8, // espacio vertical cuando bajan de línea
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

                  // 🎯 Fila 5: Actividades tipo Bullet point
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

                  // 🖼 Fila 6: Galería horizontal de fotos secundarias
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
                                // Al tocar foto, abrimos visor a pantalla completa
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
                                  destination.gallery[index],
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

                  // Espacio al final para que el scroll no quede tapado por el botón flotante
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // 🔥 Botón Fijo Inferior ("Llamado a la acción")
      bottomNavigationBar: Padding(
        // Padding asegura que no quede pegado a los bordes de la pantalla
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
            // ✅ IMPORTANTE: Navega a la pantalla del Planificador enviando el
            // destino actual como argumento. Así la IA sabe sobre qué lugar hablar.
            Navigator.pushNamed(
              context,
              '/plan', // AppRoutes.planTrip
              arguments: destination,
            );
          },
        ),
      ),
    );
  }
}

/* =========================================================================
   SUB-WIDGETS LOCALES
   (Extraídos abajo para mantener el árbol visual principal limpio)
   ========================================================================= */

/// Icono + Texto pequeño + Texto en Negrita (usado para el clima y la época)
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

/// Elemento de lista con check (usado para las actividades)
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
