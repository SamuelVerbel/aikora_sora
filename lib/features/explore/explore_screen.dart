// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../explore/models/destination_model.dart';
import '../explore/data/destinations_repository.dart';
import '../explore/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../features/auth/services/preferences_service.dart';
import '../ai/recommendation_engine.dart';

/// Pantalla Explorar Premium - Scroll vertical único y fluido
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final _repository = DestinationsRepository();
  final _scrollController = ScrollController();
  late AnimationController _animationController;

  List<Destination> _allDestinations = [];
  List<Destination> _filtered = [];
  List<Destination> _recommendedDestinations = [];

  String _recommendationTitle = "✨ Recomendado para ti";
  bool _hasRecommendations = false;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _query = '';
  
  Position? _userPosition;
  bool _sortByDistance = false;
  bool _loadingLocation = false;
  String? _categoryFilter;
  Timer? _debounce;
  double _maxPrice = 5000.0;
  double _minRating = 0.0;
  String? _selectedClimate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadSavedFilters();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['category'] != null) {
        _categoryFilter = args['category'];
      }
      _loadDestinations();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFilters() async {
    final prefs = await PreferencesService.loadPreferences();
    setState(() {
      _maxPrice = (prefs['budget'] ?? 5000.0).toDouble();
      _selectedClimate = prefs['climate'] == 'Todos' ? null : prefs['climate'];
    });
  }

  Future<void> _loadDestinations() async {
    if (!_isRefreshing) {
      LoadingOverlay.show(context, message: 'Explorando destinos increíbles...');
    }
    
    try {
      final data = await _repository.getDestinations();
      await PreferencesService.saveDestinationsCache(data);

      final engine = RecommendationEngine();
      final recommended = await engine.getTopRecommendations(data);
      final preferredType = await engine.getUserPreferredCategory();

      if (mounted) {
        setState(() {
          _allDestinations = data;
          _recommendedDestinations = recommended;
          _hasRecommendations = recommended.isNotEmpty && recommended.length >= 2;
          _recommendationTitle = preferredType != null
              ? "✨ Porque te gustan los destinos $preferredType"
              : "✨ Recomendado para ti";
          _applyFilters();
          _isLoading = false;
          _isRefreshing = false;
        });
        _animationController.forward();
      }
      LoadingOverlay.hide();
    } catch (e) {
      debugPrint('Error de red: $e');
      
      final cachedData = await PreferencesService.loadDestinationsCache();
      
      if (mounted) {
        setState(() {
          _allDestinations = cachedData;
          _hasRecommendations = false;
          _applyFilters();
          _isLoading = false;
          _isRefreshing = false;
        });
        LoadingOverlay.hide();
        
        if (cachedData.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.offline_bolt, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Modo offline: Cargando información guardada'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await _loadDestinations();
  }

  void _applyFilters() {
    List<Destination> result = List.from(_allDestinations);

    if (_query.isNotEmpty) {
      final lowercaseQuery = _query.toLowerCase();
      result = result.where((d) =>
        d.title.toLowerCase().contains(lowercaseQuery) ||
        d.country.toLowerCase().contains(lowercaseQuery) ||
        d.city.toLowerCase().contains(lowercaseQuery)
      ).toList();
    }

    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      final cat = _categoryFilter!.toLowerCase();
      result = result.where((d) =>
        d.category.toLowerCase().contains(cat) ||
        d.tags.any((t) => t.toLowerCase().contains(cat))
      ).toList();
    }

    result = result.where((d) {
      final priceInUsd = d.currency == 'COP' 
          ? d.priceMin / 4000
          : d.currency == 'EUR'
              ? d.priceMin * 1.1
              : d.priceMin;
      return priceInUsd <= _maxPrice;
    }).toList();

    if (_minRating > 0) {
      result = result.where((d) => d.rating >= _minRating).toList();
    }

    if (_selectedClimate != null && _selectedClimate != 'Todos') {
      result = result.where((d) => d.climate == _selectedClimate).toList();
    }

    if (_sortByDistance && _userPosition != null) {
      result.sort((a, b) {
        final distA = LocationService.distanceInKm(
            _userPosition!.latitude, _userPosition!.longitude,
            a.latitude, a.longitude);
        final distB = LocationService.distanceInKm(
            _userPosition!.latitude, _userPosition!.longitude,
            b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
    }

    setState(() => _filtered = result);
  }

  void _onSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _applyFilters();
      });
    });
  }

  Future<void> _toggleNearMe() async {
    if (_sortByDistance) {
      setState(() {
        _sortByDistance = false;
        _applyFilters();
      });
      return;
    }

    setState(() => _loadingLocation = true);

    Position? position;
    try {
      position = await LocationService.getCurrentPosition();
    } catch (_) {
      position = null;
    }

    if (!mounted) return;

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.location_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text('No se pudo obtener tu ubicación. Verifica los permisos.'),
            ),
          ]),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _loadingLocation = false);
      return;
    }

    setState(() {
      _userPosition = position;
      _sortByDistance = true;
      _loadingLocation = false;
      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.location_on, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Ordenando por cercanía a ti'),
        ]),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        maxPrice: _maxPrice,
        minRating: _minRating,
        selectedClimate: _selectedClimate,
        onMaxPriceChanged: (value) {
          setState(() => _maxPrice = value);
          _applyFilters();
          PreferencesService.saveBudget(value);
        },
        onMinRatingChanged: (value) {
          setState(() => _minRating = value);
          _applyFilters();
        },
        onClimateChanged: (value) {
          setState(() {
            _selectedClimate = value == 'Todos' ? null : value;
            _applyFilters();
          });
          PreferencesService.saveClimate(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070E17) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Explorar destinos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _loadingLocation
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: _sortByDistance ? 'Desactivar cercanía' : 'Cerca de mí',
                    onPressed: _toggleNearMe,
                    icon: Icon(
                      Icons.near_me,
                      color: _sortByDistance ? AppColors.accent : null,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.accent,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Header con buscador y filtros
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _SearchBar(onSearch: _onSearch),
                        const SizedBox(height: 8),
                        _ActiveFiltersChips(
                          sortByDistance: _sortByDistance,
                          categoryFilter: _categoryFilter,
                          onRemoveDistance: () {
                            setState(() {
                              _sortByDistance = false;
                              _applyFilters();
                            });
                          },
                          onRemoveCategory: () {
                            setState(() {
                              _categoryFilter = null;
                              _applyFilters();
                            });
                          },
                          onOpenFilters: _showFilterSheet,
                        ),
                        const SizedBox(height: 8),
                        _ResultCounter(
                          count: _filtered.length,
                          hasRecommendations: _hasRecommendations,
                        ),
                      ],
                    ),
                  ),

                  // Sección de recomendados (solo si hay y no hay búsqueda activa)
                  if (_hasRecommendations && _recommendedDestinations.isNotEmpty && _query.isEmpty && _categoryFilter == null)
                    SliverToBoxAdapter(
                      child: _RecommendationsSection(
                        title: _recommendationTitle,
                        destinations: _recommendedDestinations,
                        userPosition: _userPosition,
                      ),
                    ),

                  // Lista de destinos
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: _filtered.isEmpty
                        ? SliverFillRemaining(
                            child: _EmptyState(
                              onClearFilters: () {
                                setState(() {
                                  _query = '';
                                  _categoryFilter = null;
                                  _sortByDistance = false;
                                  _minRating = 0.0;
                                  _applyFilters();
                                });
                              },
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final destination = _filtered[index];
                                return FadeTransition(
                                  opacity: _animationController,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.1),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        0.1 + (index / _filtered.length) * 0.3,
                                        1.0,
                                        curve: Curves.easeOut,
                                      ),
                                    )),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _DestinationCardPremium(
                                        destination: destination,
                                        userPosition: _userPosition,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _filtered.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onSearch;

  const _SearchBar({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
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
          onChanged: onSearch,
          style: TextStyle(color: isDark ? Colors.white : Colors.grey[800]),
          decoration: InputDecoration(
            hintText: 'Buscar destino, ciudad o país...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.accent,
              size: 22,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE FILTERS CHIPS
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveFiltersChips extends StatelessWidget {
  final bool sortByDistance;
  final String? categoryFilter;
  final VoidCallback onRemoveDistance;
  final VoidCallback onRemoveCategory;
  final VoidCallback onOpenFilters;

  const _ActiveFiltersChips({
    required this.sortByDistance,
    required this.categoryFilter,
    required this.onRemoveDistance,
    required this.onRemoveCategory,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = sortByDistance || categoryFilter != null;
    
    if (!hasFilters) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Filtrar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (sortByDistance)
                    _FilterChip(
                      label: '📍 Cerca de mí',
                      onRemove: onRemoveDistance,
                    ),
                  if (categoryFilter != null)
                    _FilterChip(
                      label: '🏷️ $categoryFilter',
                      onRemove: onRemoveCategory,
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune, size: 20),
            color: AppColors.accent,
            tooltip: 'Más filtros',
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT COUNTER
// ─────────────────────────────────────────────────────────────────────────────

class _ResultCounter extends StatelessWidget {
  final int count;
  final bool hasRecommendations;

  const _ResultCounter({required this.count, required this.hasRecommendations});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.travel_explore,
            size: 14,
            color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Text(
            '$count destino${count != 1 ? 's' : ''} encontrado${count != 1 ? 's' : ''}',
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECOMMENDATIONS SECTION (Horizontal con scroll propio, pero dentro del vertical)
// ─────────────────────────────────────────────────────────────────────────────

class _RecommendationsSection extends StatelessWidget {
  final String title;
  final List<Destination> destinations;
  final Position? userPosition;

  const _RecommendationsSection({
    required this.title,
    required this.destinations,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return Container(
                width: 260,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: _CompactDestinationCard(
                  destination: destination,
                  userPosition: userPosition,
                ),
              );
            },
          ),
        ),
        const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT DESTINATION CARD (para recomendados)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactDestinationCard extends StatelessWidget {
  final Destination destination;
  final Position? userPosition;

  const _CompactDestinationCard({
    required this.destination,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? distanceLabel;
    
    if (userPosition != null) {
      final km = LocationService.distanceInKm(
        userPosition!.latitude,
        userPosition!.longitude,
        destination.latitude,
        destination.longitude,
      );
      distanceLabel = LocationService.formatDistance(km);
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.destinationDetail,
        arguments: destination,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111D2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: destination.mainImage,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: Colors.grey.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          destination.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distanceLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.near_me, size: 10, color: AppColors.accent),
                              const SizedBox(width: 2),
                              Text(
                                distanceLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${destination.city}, ${destination.country}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${destination.rating}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' (${destination.reviews})',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM DESTINATION CARD (para lista principal)
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationCardPremium extends StatelessWidget {
  final Destination destination;
  final Position? userPosition;

  const _DestinationCardPremium({
    required this.destination,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? distanceLabel;
    
    if (userPosition != null) {
      final km = LocationService.distanceInKm(
        userPosition!.latitude,
        userPosition!.longitude,
        destination.latitude,
        destination.longitude,
      );
      distanceLabel = LocationService.formatDistance(km);
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.destinationDetail,
        arguments: destination,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111D2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Hero(
                    tag: destination.id,
                    child: CachedNetworkImage(
                      imageUrl: destination.mainImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: Colors.grey.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey.withOpacity(0.2),
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                  ),
                ),
                if (distanceLabel != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      child: Row(
                        children: [
                          const Icon(Icons.near_me, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            distanceLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          destination.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${destination.currency} ${destination.priceMin.toInt()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${destination.city}, ${destination.country}',
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    destination.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        '${destination.rating}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${destination.reviews} reseñas)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          destination.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BOTTOM SHEET PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  final double maxPrice;
  final double minRating;
  final String? selectedClimate;
  final ValueChanged<double> onMaxPriceChanged;
  final ValueChanged<double> onMinRatingChanged;
  final ValueChanged<String> onClimateChanged;

  const _FilterBottomSheet({
    required this.maxPrice,
    required this.minRating,
    required this.selectedClimate,
    required this.onMaxPriceChanged,
    required this.onMinRatingChanged,
    required this.onClimateChanged,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late double _maxPrice;
  late double _minRating;
  late String _selectedClimate;

  @override
  void initState() {
    super.initState();
    _maxPrice = widget.maxPrice;
    _minRating = widget.minRating;
    _selectedClimate = widget.selectedClimate ?? 'Todos';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111D2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filtros avanzados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Presupuesto máximo', style: TextStyle(fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'USD \$${_maxPrice.toInt()}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _maxPrice,
                  min: 0,
                  max: 10000,
                  divisions: 20,
                  activeColor: AppColors.accent,
                  onChanged: (value) {
                    setState(() => _maxPrice = value);
                    widget.onMaxPriceChanged(value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rating mínimo', style: TextStyle(fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _minRating == 0 ? 'Todos' : _minRating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  activeColor: Colors.amber,
                  onChanged: (value) {
                    setState(() => _minRating = value);
                    widget.onMinRatingChanged(value);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Clima', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Todos', 'Cálido', 'Frío', 'Templado'].map((climate) {
                    final isSelected = _selectedClimate == climate;
                    return FilterChip(
                      label: Text(climate),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedClimate = climate);
                        widget.onClimateChanged(climate);
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: AppColors.accent.withOpacity(0.2),
                      checkmarkColor: AppColors.accent,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.accent : null,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.accent
                            : (isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Aplicar filtros',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
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
            Icons.search_off_rounded,
            size: 80,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron destinos',
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