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
  
  // FIX: Controlar visibilidad de la sección de recomendados
  bool _hasRecommendations = false;

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
      _maxPrice = (prefs['budget'] ?? 5000.0).toDouble();
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

    try {
      // 1. Intentar obtener datos de la red
      final data = await _repository.getDestinations();
      
      // 2. RF-11: Guardar en local apenas descargue
      await PreferencesService.saveDestinationsCache(data);

      final engine = RecommendationEngine();
      final recommended = await engine.getTopRecommendations(data);
      final preferredType = await engine.getUserPreferredCategory();

      if (mounted) {
        setState(() {
          _allDestinations = data;
          _recommendedDestinations = recommended;
          // FIX: Solo mostrar recomendados si hay al menos 2 destinos
          _hasRecommendations = recommended.isNotEmpty && recommended.length >= 2;
          _recommendationTitle = preferredType != null
              ? "✨ Porque te gustan los destinos $preferredType"
              : "✨ Recomendado para ti";
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error de red, cargando caché local: $e');
      
      // 3. Fallback: Cargar del disco si no hay internet (Resiliencia Premium)
      final cachedData = await PreferencesService.loadDestinationsCache();
      
      if (mounted) {
        setState(() {
          _allDestinations = cachedData;
          _hasRecommendations = false; // En offline no mostrar recomendados
          _applyFilters(); // Aplicar filtros sobre los datos cacheados
          _isLoading = false;
        });
        
        if (cachedData.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Modo offline: Cargando información guardada')),
          );
        }
      }
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
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_sortByDistance)
                    _FilterChip(
                      label: '📍 Cerca de mí',
                      onRemove: () => setState(() {
                        _sortByDistance = false;
                        _applyFilters();
                      }),
                    ),
                  if (_categoryFilter != null)
                    _FilterChip(
                      label: '🏷️ $_categoryFilter',
                      onRemove: () => setState(() {
                        _categoryFilter = null;
                        _applyFilters();
                      }),
                    ),
                ],
              ),
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

          // FIX: Sección Recomendados por IA - Mejorada visualmente
          if (_hasRecommendations && _recommendedDestinations.isNotEmpty && !_isLoading)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      _recommendationTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 280, // FIX: Altura reducida para mejor visualización
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _recommendedDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = _recommendedDestinations[index];
                        return Container(
                          width: 260,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: DestinationCard(
                            destination: destination,
                            userPosition: _userPosition,
                            heroPrefix: 'rec_',
                            compact: true, // FIX: Modo compacto para recomendados
                          ),
                        );
                      },
                    ),
                  ),
                  // FIX: Separador sutil entre secciones
                  const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
                ],
              ),
            ),

          // Lista de resultados - FIX: Mejor manejo del espacio
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadDestinations,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filtered.length,
                          cacheExtent: 800,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: DestinationCard(
                              destination: _filtered[i],
                              userPosition: _userPosition,
                              compact: false,
                            ),
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
          Icon(Icons.search_off, size: 64, color: Colors.grey.withOpacity(0.35)),
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
  final String heroPrefix;
  final bool compact; // FIX: Modo compacto para cards de recomendados

  const DestinationCard({
    super.key,
    required this.destination,
    this.userPosition,
    this.heroPrefix = '',
    this.compact = false,
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

    // FIX: Altura de imagen dinámica según modo compacto
    final imageHeight = compact ? 140.0 : 200.0;
    final padding = compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16);
    final titleStyle = compact 
        ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        : const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

    return Card(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: compact ? 2 : 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Hero(
              tag: '$heroPrefix${destination.id}',
              child: CachedNetworkImage(
                imageUrl: destination.mainImage,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: imageHeight,
                  color: Colors.grey.withOpacity(0.12),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: imageHeight,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(destination.title,
                          style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (distanceLabel != null && !compact) // FIX: Solo mostrar distancia si no es compacto
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
                  Expanded(
                    child: Text('${destination.city}, ${destination.country}',
                        style: TextStyle(color: Colors.grey[600], fontSize: compact ? 12 : 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 8),
                if (!compact) // FIX: Solo mostrar descripción si no es compacto
                  Text(destination.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${destination.rating} (${destination.reviews} reseñas)',
                    style: TextStyle(fontSize: compact ? 12 : 13),
                  ),
                ]),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14),
                      minimumSize: const Size(0, 0),
                    ),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.destinationDetail,
                      arguments: destination,
                    ),
                    child: Text(compact ? 'Ver' : 'Ver más'),
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