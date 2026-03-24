import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_overlay.dart';
import 'restaurant_model.dart';
import 'restaurants_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/core/utils/map_launcher_service.dart';

/// Pantalla de restaurantes premium con diseño moderno
class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen>
    with SingleTickerProviderStateMixin {
  final _service = RestaurantsService();

  List<Restaurant> _all = [];
  List<Restaurant> _filtered = [];
  bool _isLoading = true;
  String _query = '';
  String? _selectedCuisine;
  String? _destinationId;
  String? _destinationName;
  double? _lat;
  double? _lng;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;

      if (args != null) {
        _destinationId = args['destinationId'];
        _destinationName = args['destinationName'];
        _lat = args['lat'];
        _lng = args['lng'];
      }

      _loadRestaurants();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    LoadingOverlay.show(context, message: 'Buscando los mejores lugares...');

    List<Restaurant> data;

    if (_lat != null && _lng != null) {
      data = await _service.getRealTimeRestaurants(
        lat: _lat!,
        lng: _lng!,
        destinationId: _destinationId ?? 'unknown',
      );
    } else {
      data = await _service.getAll();
    }

    if (!mounted) return;

    setState(() {
      _all = data;
      _applyFilters();
      _isLoading = false;
    });
    _animationController.forward();
    LoadingOverlay.hide();
  }

  void _applyFilters() {
    List<Restaurant> result = List.from(_all);

    if (_query.isNotEmpty) {
      result = result
          .where((r) =>
              r.name.toLowerCase().contains(_query.toLowerCase()) ||
              r.cuisine.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    if (_selectedCuisine != null) {
      result = result
          .where((r) =>
              r.cuisine.toLowerCase() == _selectedCuisine!.toLowerCase())
          .toList();
    }

    _filtered = result;
  }

  List<String> get _cuisines {
    final list = _all.map((r) => r.cuisine).toSet().toList();
    list.sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070E17) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _destinationName != null
              ? 'Restaurantes en $_destinationName'
              : 'Restaurantes',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? const Color(0xFF0B1520) : Colors.white,
                isDark ? const Color(0xFF0F1A2A) : Colors.grey[50]!,
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── BUSCADOR PREMIUM ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar restaurante o tipo de cocina...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: isDark
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.grey[500]),
                          onPressed: () => setState(() {
                            _query = '';
                            _applyFilters();
                          }),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) => setState(() {
                  _query = v;
                  _applyFilters();
                }),
              ),
            ),
          ),

          // ── CHIPS DE COCINA PREMIUM ───────────────────────────────────
          if (_cuisines.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CuisineChip(
                    label: 'Todas',
                    isSelected: _selectedCuisine == null,
                    onTap: () => setState(() {
                      _selectedCuisine = null;
                      _applyFilters();
                    }),
                  ),
                  ..._cuisines.map((c) => _CuisineChip(
                        label: c,
                        isSelected: _selectedCuisine == c,
                        onTap: () => setState(() {
                          _selectedCuisine = _selectedCuisine == c ? null : c;
                          _applyFilters();
                        }),
                      )),
                ],
              ),
            ),

          // ── CONTADOR DE RESULTADOS ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  size: 14,
                  color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  '${_filtered.length} restaurante${_filtered.length != 1 ? "s" : ""}',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ── LISTA DE RESTAURANTES PREMIUM ────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : _filtered.isEmpty
                    ? _EmptyState(
                        onClearFilters: () => setState(() {
                          _query = '';
                          _selectedCuisine = null;
                          _applyFilters();
                        }),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRestaurants,
                        color: AppColors.accent,
                        child: AnimationLimiter(
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 500),
                                child: SlideAnimation(
                                  verticalOffset: 50,
                                  child: FadeInAnimation(
                                    child: _RestaurantCardPremium(
                                      restaurant: _filtered[index],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUISINE CHIP PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _CuisineChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CuisineChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.accent,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESTAURANT CARD PREMIUM (SIN ADDRESS NI PHONE)
// ─────────────────────────────────────────────────────────────────────────────

class _RestaurantCardPremium extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantCardPremium({required this.restaurant});

  String get _priceLabel {
    switch (restaurant.priceRange) {
      case 'low':
        return '\$';
      case 'mid':
        return '\$\$';
      case 'high':
        return '\$\$\$';
      default:
        return restaurant.priceRange;
    }
  }

  Future<void> _openMap() async {
    await MapLauncherService.openGoogleMapsWithName(
      name: restaurant.name,
      lat: restaurant.latitude,
      lng: restaurant.longitude,
      address: '', // Sin dirección por ahora
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111D2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
                child: restaurant.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: restaurant.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: Colors.grey.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey.withOpacity(0.2),
                          child: const Icon(Icons.restaurant_outlined,
                              size: 50),
                        ),
                      )
                    : Container(
                        height: 180,
                        color: Colors.grey.withOpacity(0.2),
                        child: const Icon(Icons.restaurant_outlined,
                            size: 50),
                      ),
              ),
              // Badge de precio
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    _priceLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Badge de rating
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.restaurant_menu_outlined,
                        size: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      restaurant.cuisine,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    // Botón mapa (solo si hay coordenadas válidas)
                    if (restaurant.latitude != 0 && restaurant.longitude != 0)
                      TextButton.icon(
                        onPressed: _openMap,
                        icon: Icon(Icons.map_outlined,
                            size: 16, color: AppColors.accent),
                        label: Text(
                          'Ver mapa',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _EmptyState({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 80,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron restaurantes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros filtros o palabras clave',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Limpiar filtros'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}