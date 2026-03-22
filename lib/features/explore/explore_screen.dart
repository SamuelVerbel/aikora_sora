// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../explore/models/destination_model.dart';
import '../explore/data/destinations_repository.dart';
import '../explore/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../features/auth/services/preferences_service.dart';
import '../ai/recommendation_engine.dart';

/// Pantalla Explorar.
/// Muestra TODOS los destinos y permite buscar por texto,
/// filtrar por categoría y ordenar por cercanía usando el GPS del usuario.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repository = DestinationsRepository();

  List<Destination> _allDestinations = [];
  List<Destination> _filtered = [];
  List<Destination> _recommendedDestinations = [];

  // FIX 1: título dinámico — se actualiza desde _loadDestinations()
  String _recommendationTitle = "✨ Recomendado para ti";

  bool _isLoading = true;
  String _query = '';

  Position? _userPosition;
  bool _sortByDistance = false;
  bool _loadingLocation = false;
  String? _categoryFilter;
  Timer? _debounce;
  double _maxPrice = 5000.0;
  double _minRating = 0.0;
  String? _selectedClimate;

  Future<void> _loadSavedFilters() async {
    final prefs = await PreferencesService.loadPreferences();
    setState(() {
      _maxPrice = prefs['budget'];
      _selectedClimate = prefs['climate'] == 'Todos' ? null : prefs['climate'];
    });
  }

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Future<void> _loadDestinations() async {
    setState(() => _isLoading = true);

    final data = await _repository.getDestinations();
    final engine = RecommendationEngine();
    final ranked = await engine.rankDestinations(data);
    final recommended = await engine.getTopRecommendations(data);
    final preferredType = await engine.getUserPreferredCategory();

    if (mounted) {
      setState(() {
        _allDestinations = ranked;
        _recommendedDestinations = recommended;

        // FIX 1: título dinámico correctamente asignado a la variable de estado
        _recommendationTitle = preferredType != null
            ? "✨ Porque te gustan los destinos $preferredType"
            : "✨ Recomendado para ti";

        _applyFilters();
        _isLoading = false;
      });
    }
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

    result = result.where((d) => d.priceMin <= _maxPrice).toList();

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

  /// FIX 3: GPS web-safe con try/catch explícito
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
      // Web puede lanzar excepción en contexto HTTP o si el navegador bloquea
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
              child: Text('No se pudo obtener tu ubicación. '
                  'Verifica los permisos del navegador o dispositivo.'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar destinos'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _loadingLocation
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
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
      body: Column(
        children: [
          // Buscador + Botón Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar ciudad o país',
                      prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: _onSearch,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.accent),
                    onPressed: _showFilterSheet,
                  ),
                ),
              ],
            ),
          ),

          // Chips de filtros activos
          if (_sortByDistance || _categoryFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                if (_sortByDistance)
                  _FilterChip(
                    label: '📍 Cerca de mí',
                    onRemove: () => setState(() {
                      _sortByDistance = false;
                      _applyFilters();
                    }),
                  ),
                if (_categoryFilter != null) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '🏷️ $_categoryFilter',
                    onRemove: () => setState(() {
                      _categoryFilter = null;
                      _applyFilters();
                    }),
                  ),
                ],
              ]),
            ),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} destino${_filtered.length != 1 ? 's' : ''} encontrado${_filtered.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),

          // Sección Recomendados por IA
          if (_recommendedDestinations.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  // FIX 1: sin const para poder usar la variable _recommendationTitle
                  child: Text(
                    _recommendationTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recommendedDestinations.length,
                    itemBuilder: (context, index) {
                      final destination = _recommendedDestinations[index];
                      return SizedBox(
                        width: 260,
                        child: DestinationCard(
                          destination: destination,
                          userPosition: _userPosition,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          // Lista de resultados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadDestinations,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _filtered.length,
                          cacheExtent: 800,
                          itemBuilder: (_, i) => DestinationCard(
                            destination: _filtered[i],
                            userPosition: _userPosition,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtros Avanzados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // 1. Presupuesto máximo
                Text('Presupuesto Máximo: \$${_maxPrice.toInt()}'),
                Slider(
                  value: _maxPrice,
                  min: 0,
                  max: 10000,
                  divisions: 20,
                  activeColor: AppColors.accent,
                  onChanged: (double value) {
                    setModalState(() => _maxPrice = value);
                    setState(() => _maxPrice = value);
                    _applyFilters();
                    PreferencesService.saveBudget(value);
                  },
                ),

                const SizedBox(height: 10),

                // FIX 2: Rating mínimo — slider que antes faltaba
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rating mínimo'),
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _minRating == 0
                            ? 'Todos'
                            : _minRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ],
                ),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  activeColor: Colors.amber,
                  onChanged: (double value) {
                    setModalState(() => _minRating = value);
                    setState(() => _minRating = value);
                    _applyFilters();
                  },
                ),

                const SizedBox(height: 10),

                // 3. Clima
                const Text('Preferencia de Clima'),
                DropdownButton<String>(
                  value: _selectedClimate ?? 'Todos',
                  isExpanded: true,
                  items: <String>['Todos', 'Cálido', 'Frío', 'Templado']
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setModalState(() {
                        _selectedClimate =
                            (newValue == 'Todos') ? null : newValue;
                      });
                      setState(() {
                        _selectedClimate =
                            (newValue == 'Todos') ? null : newValue;
                      });
                      _applyFilters();
                      PreferencesService.saveClimate(newValue);
                    }
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Aplicar Filtros'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No se encontraron destinos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _query = '';
                _categoryFilter = null;
                _sortByDistance = false;
                _minRating = 0.0;
                _applyFilters();
              });
            },
            child: const Text('Limpiar filtros',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTES REUTILIZABLES
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 14, color: AppColors.accent),
        ),
      ]),
    );
  }
}

class DestinationCard extends StatelessWidget {
  final Destination destination;
  final Position? userPosition;

  const DestinationCard({
    super.key,
    required this.destination,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    String? distanceLabel;
    if (userPosition != null &&
        destination.latitude != null &&
        destination.longitude != null) {
      final km = LocationService.distanceInKm(
        userPosition!.latitude,
        userPosition!.longitude,
        destination.latitude,
        destination.longitude,
      );
      distanceLabel = LocationService.formatDistance(km);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Hero(
              tag: destination.id,
              child: CachedNetworkImage(
                imageUrl: destination.mainImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
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
                      child: Text(destination.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    if (distanceLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.near_me,
                              size: 12, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(distanceLabel,
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text('${destination.city}, ${destination.country}',
                      style: TextStyle(color: Colors.grey[600])),
                ]),
                const SizedBox(height: 8),
                Text(destination.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${destination.rating} (${destination.reviews} reseñas)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ]),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.destinationDetail,
                      arguments: destination,
                    ),
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