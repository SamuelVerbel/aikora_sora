// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../models/destination_model.dart';
import 'gallery_fullscreen_screen.dart';
import '../../reservations/create_reservation_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../ai/user_behavior_service.dart';
import '../../ai/chat_screen.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/loading_overlay.dart';

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

class _DestinationDetailScreenState extends State<DestinationDetailScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late AnimationController _animationController;
  int _currentSlide = 0;
  bool _isMapExpanded = false;

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── SLIDER DE IMÁGENES PREMIUM ─────────────────────────────────
          SizedBox(
            height: 420,
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
                      child: Hero(
                        tag: 'hero_${dest.id}_$index',
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
                      ),
                    );
                  },
                ),

                // Degradado inferior mejorado
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 200,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ),

                // Título y ubicación con efecto glass
                Positioned(
                  bottom: 44, left: 24, right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dest.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black45)
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${dest.city}, ${dest.country}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  dest.rating.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dots indicadores premium
                if (images.length > 1)
                  Positioned(
                    bottom: 18, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (i) {
                        final isActive = i == _currentSlide;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.accent
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                // Contador "1 / N" premium
                if (images.length > 1)
                  Positioned(
                    top: 56, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
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

          // ── BOTÓN VOLVER PREMIUM ───────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // ── BOTÓN SORA PREMIUM ─────────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: GestureDetector(
                  onTap: _openSoraChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.6)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✨', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Text(
                          'Preguntarle a Sora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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

          // ── CONTENIDO DESLIZABLE PREMIUM ───────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1520) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Rating + precio premium
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${dest.rating} (${dest.reviews} reseñas)',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          if (dest.priceMin > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withOpacity(0.2),
                                    AppColors.accent.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
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

                      const SizedBox(height: 24),

                      // Info rápida premium
                      if (dest.climate.isNotEmpty || dest.bestSeason.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[50]!,
                                isDark
                                    ? Colors.white.withOpacity(0.02)
                                    : Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
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
                                _InfoChipPremium(
                                  icon: Icons.wb_sunny_outlined,
                                  label: 'Clima',
                                  value: dest.climate,
                                ),
                              if (dest.bestSeason.isNotEmpty)
                                _InfoChipPremium(
                                  icon: Icons.calendar_month_outlined,
                                  label: 'Mejor época',
                                  value: dest.bestSeason,
                                ),
                              if (dest.durationMin > 0)
                                _InfoChipPremium(
                                  icon: Icons.schedule_outlined,
                                  label: 'Duración',
                                  value:
                                      '${dest.durationMin}-${dest.durationMax} días',
                                ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dest.description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Tags
                      if (dest.tags.isNotEmpty) ...[
                        const Text(
                          'Tipo de destino',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: dest.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.accent
                                              .withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Actividades
                      if (dest.activities.isNotEmpty) ...[
                        const Text(
                          'Actividades disponibles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...dest.activities
                            .map((activity) => _BulletPointPremium(
                                  text: activity,
                                  isDark: isDark,
                                ))
                            .toList(),
                        const SizedBox(height: 28),
                      ],

                      // Mapa (si tiene coordenadas)
                      if (dest.latitude != 0 && dest.longitude != 0) ...[
                        const Text(
                          'Ubicación',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() => _isMapExpanded = !_isMapExpanded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _isMapExpanded ? 300 : 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(dest.latitude, dest.longitude),
                                  zoom: 12,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('destination'),
                                    position:
                                        LatLng(dest.latitude, dest.longitude),
                                    infoWindow: InfoWindow(
                                      title: dest.title,
                                      snippet: '${dest.city}, ${dest.country}',
                                    ),
                                  ),
                                },
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => setState(() => _isMapExpanded = !_isMapExpanded),
                            icon: Icon(
                              _isMapExpanded
                                  ? Icons.compress
                                  : Icons.fullscreen,
                              size: 16,
                            ),
                            label: Text(
                              _isMapExpanded ? 'Reducir mapa' : 'Expandir mapa',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ── BOTONES INFERIORES PREMIUM ─────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1520) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón restaurantes
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                        color: AppColors.accent.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.restaurant_menu,
                      color: AppColors.accent),
                  label: const Text(
                    'Ver Restaurantes',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                            color: AppColors.accent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
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
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
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
                            builder: (_) => CreateReservationScreen(
                                destination: dest),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTES PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChipPremium extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChipPremium({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500])),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BulletPointPremium extends StatelessWidget {
  final String text;
  final bool isDark;

  const _BulletPointPremium({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check,
                color: AppColors.accent, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}