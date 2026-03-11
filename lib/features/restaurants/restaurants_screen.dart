import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'restaurant_model.dart';
import 'restaurants_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/core/utils/map_launcher_service.dart';

/// Pantalla de restaurantes.
/// Tiene dos modos:
/// - Con argumento 'destinationId': muestra solo los de ese destino.
/// - Sin argumento: muestra todos los restaurantes.
class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final _service = RestaurantsService();

  List<Restaurant> _all = [];      // Lista completa sin filtros
  List<Restaurant> _filtered = []; // Lista que se muestra en pantalla
  bool _isLoading = true;
  String _query = '';              // Texto del buscador
  String? _selectedCuisine;       // Filtro activo de tipo de cocina
  String? _destinationId;         // Si viene de un destino específico
  String? _destinationName;       // Para mostrar en el AppBar
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map?;

      if (args != null) {
        _destinationId = args['destinationId'];
        _destinationName = args['destinationName'];
        _lat = args['lat'];
        _lng = args['lng'];
      }

      _loadRestaurants();
    });
  }

  // 1. Actualiza la carga de datos para usar Google Places si hay coordenadas
  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);

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
  }

  /// Motor de filtrado: combina búsqueda de texto + tipo de cocina.
  void _applyFilters() {
    List<Restaurant> result = List.from(_all);

    // Filtro por texto (nombre o tipo de cocina)
    if (_query.isNotEmpty) {
      result = result
          .where((r) =>
              r.name.toLowerCase().contains(_query.toLowerCase()) ||
              r.cuisine.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    // Filtro por tipo de cocina seleccionado
    if (_selectedCuisine != null) {
      result = result
          .where((r) =>
              r.cuisine.toLowerCase() == _selectedCuisine!.toLowerCase())
          .toList();
    }

    _filtered = result;
  }

  /// Extrae los tipos de cocina únicos para los chips de filtro.
  List<String> get _cuisines {
    final list = _all.map((r) => r.cuisine).toSet().toList();
    list.sort(); // Orden alfabético
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Título dinámico: si viene de un destino lo menciona
        title: Text(
          _destinationName != null
              ? 'Restaurantes en $_destinationName'
              : 'Restaurantes',
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [

          // ── 1. Buscador de texto ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o cocina',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.accent),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                // Botón X para limpiar el buscador
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _query = '';
                          _applyFilters();
                        }),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() {
                _query = v;
                _applyFilters(); // Filtra en tiempo real
              }),
            ),
          ),

          // ── 2. Chips de tipo de cocina (scroll horizontal) ────────
          // Solo se muestran si hay datos cargados
          if (_cuisines.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                children: [
                  // Chip especial "Todas" para quitar el filtro
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Todas'),
                      selected: _selectedCuisine == null,
                      selectedColor: AppColors.accent.withOpacity(0.2),
                      checkmarkColor: AppColors.accent,
                      onSelected: (_) => setState(() {
                        _selectedCuisine = null;
                        _applyFilters();
                      }),
                    ),
                  ),
                  // Un chip por cada tipo de cocina disponible
                  ..._cuisines.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(c),
                          selected: _selectedCuisine == c,
                          selectedColor: AppColors.accent.withOpacity(0.2),
                          checkmarkColor: AppColors.accent,
                          onSelected: (_) => setState(() {
                            // Si ya estaba seleccionada la deselecciona
                            _selectedCuisine =
                                _selectedCuisine == c ? null : c;
                            _applyFilters();
                          }),
                        ),
                      )),
                ],
              ),
            ),

          // ── 3. Contador de resultados ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Text(
                '${_filtered.length} restaurante${_filtered.length != 1 ? "s" : ""}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ]),
          ),

          // ── 4. Lista de resultados ────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRestaurants,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _RestaurantCard(restaurant: _filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Pantalla vacía cuando no hay resultados con los filtros actuales.
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No se encontraron restaurantes',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          // Botón de escape solo si hay filtros activos
          if (_selectedCuisine != null || _query.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _query = '';
                _selectedCuisine = null;
                _applyFilters();
              }),
              child: const Text('Limpiar filtros',
                  style: TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
    );
  }
}

/* =========================================================================
   COMPONENTES LOCALES
   ========================================================================= */

/// Tarjeta horizontal para mostrar la info de un restaurante.
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  String get _priceLabel {
    switch (restaurant.priceRange) {
      case 'low': return '\$';
      case 'mid': return '\$\$';
      case 'high': return '\$\$\$';
      default: return restaurant.priceRange;
    }
  }

  Widget _placeholder() {
    return Container(
      width: 110,
      height: 110,
      color: Colors.grey[300],
      child: Icon(Icons.restaurant_outlined,
          color: Colors.grey[600], size: 40),
    );
  }

  Future<void> _openMap() async {
    if (restaurant.latitude == 0 || restaurant.longitude == 0) return;

    await MapLauncherService.openGoogleMaps(
      restaurant.latitude,
      restaurant.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Row(
        children: [

          // Imagen
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: restaurant.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    width: 110,
                    height: 130,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 110,
                      height: 130,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    restaurant.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Row(children: [
                    const Icon(Icons.restaurant_menu_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(restaurant.cuisine,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ]),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _priceLabel,
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 🔥 NUEVO BOTÓN MAPA
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Ver en mapa'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                      ),
                      onPressed: _openMap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}