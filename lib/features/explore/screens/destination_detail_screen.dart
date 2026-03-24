// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/destination_model.dart';
import 'gallery_fullscreen_screen.dart';
import '../../reservations/create_reservation_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../ai/user_behavior_service.dart';
import '../../ai/chat_screen.dart';
import '../../../core/routes/app_routes.dart';

class DestinationDetailScreen extends StatefulWidget {
  final Destination destination;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
  });

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  late final PageController _pageController;
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    final behavior = UserBehaviorService();
    behavior.registerDestinationView(widget.destination.id);
    behavior.learnTravelPreference(
      widget.destination.id,
      widget.destination.category,
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Combina mainImage + gallery sin duplicados, máximo 6 imágenes
  List<String> get _allImages {
    final images = <String>[];
    if (widget.destination.mainImage.isNotEmpty) {
      images.add(widget.destination.mainImage);
    }
    for (final img in widget.destination.gallery) {
      if (img.isNotEmpty && !images.contains(img)) images.add(img);
    }
    return images.take(6).toList();
  }

  void _openSoraChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(destination: widget.destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _allImages;
    final dest = widget.destination;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [

          // ── SLIDER DE IMÁGENES ─────────────────────────────────────────
          SizedBox(
            height: 360,
            width: double.infinity,
            child: Stack(
              children: [

                PageView.builder(
                  controller: _pageController,
                  itemCount: images.isEmpty ? 1 : images.length,
                  onPageChanged: (index) =>
                      setState(() => _currentSlide = index),
                  itemBuilder: (context, index) {
                    final imageUrl = images.isEmpty ? '' : images[index];
                    return GestureDetector(
                      onTap: () {
                        if (images.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GalleryFullscreenScreen(
                                images: images,
                                initialIndex: index,
                              ),
                            ),
                          );
                        }
                      },
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.withOpacity(0.12),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  Container(
                                color: Colors.grey.withOpacity(0.2),
                                child: const Icon(
                                    Icons.image_not_supported,
                                    size: 60),
                              ),
                            )
                          : Container(
                              color: Colors.grey.withOpacity(0.2),
                              child: const Icon(Icons.image_not_supported,
                                  size: 60),
                            ),
                    );
                  },
                ),

                // Degradado inferior
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 180,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ),

                // Título y ubicación sobre el gradiente
                Positioned(
                  bottom: 44, left: 24, right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dest.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black45)
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${dest.city}, ${dest.country}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ]),
                    ],
                  ),
                ),

                // Dots indicadores
                if (images.length > 1)
                  Positioned(
                    bottom: 18, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (i) {
                        final isActive = i == _currentSlide;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                // Contador "1 / N"
                if (images.length > 1)
                  Positioned(
                    top: 56, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentSlide + 1} / ${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── BOTÓN VOLVER ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // ── BOTÓN SORA — único, esquina superior derecha ───────────────
          // RF-21: abre ChatScreen con contexto del destino precargado.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: GestureDetector(
                  onTap: _openSoraChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✨', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 5),
                        Text(
                          'Preguntarle a Sora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── CONTENIDO DESLIZABLE ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 310),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Rating + precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text(
                            '${dest.rating} (${dest.reviews} reseñas)',
                            style: const TextStyle(fontSize: 14)),
                      ]),
                      if (dest.priceMin > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${dest.currency} ${dest.priceMin.toInt()} - ${dest.priceMax.toInt()}/noche',
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

                  // Info rápida — clima, temporada, duración
                  if (dest.climate.isNotEmpty || dest.bestSeason.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (dest.climate.isNotEmpty)
                            _InfoChip(
                              icon: Icons.wb_sunny_outlined,
                              label: 'Clima',
                              value: dest.climate,
                            ),
                          if (dest.bestSeason.isNotEmpty)
                            _InfoChip(
                              icon: Icons.calendar_month_outlined,
                              label: 'Mejor época',
                              value: dest.bestSeason,
                            ),
                          if (dest.durationMin > 0)
                            _InfoChip(
                              icon: Icons.schedule_outlined,
                              label: 'Duración',
                              value:
                                  '${dest.durationMin}-${dest.durationMax} días',
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Descripción
                  const Text('Descripción',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(dest.description,
                      style:
                          const TextStyle(fontSize: 16, height: 1.6)),

                  const SizedBox(height: 24),

                  // Tags
                  if (dest.tags.isNotEmpty) ...[
                    const Text('Tipo de destino',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dest.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor:
                                    AppColors.accent.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(
                                    color: AppColors.accent, fontSize: 13),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actividades
                  if (dest.activities.isNotEmpty) ...[
                    const Text('Actividades disponibles',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...dest.activities
                        .map((activity) => BulletPoint(text: activity))
                        .toList(),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── BOTONES INFERIORES ─────────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.restaurant_menu,
                    color: AppColors.accent),
                label: const Text('Ver Restaurantes',
                    style: TextStyle(
                        color: AppColors.accent, fontSize: 15)),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/restaurants',
                    arguments: {
                      'destinationId': dest.id,
                      'destinationName': dest.title,
                      'lat': dest.latitude != 0 ? dest.latitude : null,
                      'lng': dest.longitude != 0 ? dest.longitude : null,
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: const Icon(Icons.auto_awesome,
                        color: AppColors.accent),
                    label: const Text('Planear con IA',
                        style: TextStyle(
                            color: AppColors.accent, fontSize: 15)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/plan',
                          arguments: dest);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: const Icon(Icons.bookmark_add_outlined,
                        color: Colors.white),
                    label: const Text('Reservar',
                        style: TextStyle(
                            fontSize: 15, color: Colors.white)),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            CreateReservationScreen(destination: dest),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Componentes locales
// ─────────────────────────────────────────────────────────────────────────────

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
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}