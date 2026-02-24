import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../explore/models/destination_model.dart';
import '../explore/data/destinations_repository.dart';
import '../explore/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repository = DestinationsRepository();
  List<Destination> _allDestinations = [];
  List<Destination> _filtered = [];
  bool _isLoading = true;
  String _query = '';

  // Geo
  Position? _userPosition;
  bool _sortByDistance = false;
  bool _loadingLocation = false;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    // Recibir categoría desde Home si viene como argumento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['category'] != null) {
        _categoryFilter = args['category'];
      }
      _loadDestinations();
    });
  }

  Future<void> _loadDestinations() async {
    setState(() => _isLoading = true);
    final data = await _repository.getDestinations();
    if (mounted) {
      setState(() {
        _allDestinations = data;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Destination> result = List.from(_allDestinations);

    // Filtro de búsqueda
    if (_query.isNotEmpty) {
      result = result.where((d) =>
        d.title.toLowerCase().contains(_query.toLowerCase()) ||
        d.country.toLowerCase().contains(_query.toLowerCase()) ||
        d.city.toLowerCase().contains(_query.toLowerCase())
      ).toList();
    }

    // Filtro de categoría (desde Home)
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      result = result.where((d) =>
        d.category.toLowerCase().contains(_categoryFilter!) ||
        (d.tags.any((t) => t.toLowerCase().contains(_categoryFilter!)) ?? false)
      ).toList();
    }

    // Ordenar por distancia
    if (_sortByDistance && _userPosition != null) {
      result.sort((a, b) {
        final distA = (a.longitude != null)
            ? LocationService.distanceInKm(
                _userPosition!.latitude, _userPosition!.longitude,
                a.latitude, a.longitude)
            : double.infinity;
        final distB = (b.longitude != null)
            ? LocationService.distanceInKm(
                _userPosition!.latitude, _userPosition!.longitude,
                b.latitude, b.longitude)
            : double.infinity;
        return distA.compareTo(distB);
      });
    }

    _filtered = result;
  }

  void _onSearch(String value) {
    setState(() {
      _query = value;
      _applyFilters();
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

    final position = await LocationService.getCurrentPosition();

    if (position == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.location_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('No se pudo obtener tu ubicación'),
          ]),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _loadingLocation = false);
      return;
    }

    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar destinos'),
        centerTitle: true,
        actions: [
          // Botón cerca de mí
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
                      color: _sortByDistance
                          ? AppColors.accent
                          : null,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar ciudad o país',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.accent),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),

          // Chips de estado activo
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

          // Contador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} destino${_filtered.length != 1 ? 's' : ''} encontrado${_filtered.length != 1 ? 's' : ''}',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),

          // Lista
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

/* ── Filter chip ─────────────────────────────────── */

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

/* ── Destination Card ────────────────────────────── */

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
    // Calcular distancia si tenemos coordenadas
    String? distanceLabel;
    if (userPosition != null) {
      final km = LocationService.distanceInKm(
        userPosition!.latitude, userPosition!.longitude,
        destination.latitude, destination.longitude,
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
          // Imagen
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Hero(
              tag: destination.id,
              child: Image.network(
                destination.mainImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
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
                    // Badge distancia
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
