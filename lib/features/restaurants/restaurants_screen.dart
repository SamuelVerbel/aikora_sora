import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'restaurant_model.dart';
import 'restaurants_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    // addPostFrameCallback asegura que el widget ya esté montado
    // antes de leer los argumentos de la ruta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _destinationId = args['destinationId'];
        _destinationName = args['destinationName'];
      }
      _loadRestaurants();
    });
  }

  /// Carga restaurantes desde Supabase según el modo activo.
  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);

    // Si hay destinationId cargamos solo los de ese destino,
    // si no, cargamos todos
    final data = _destinationId != null
        ? await _service.getByDestination(_destinationId!)
        : await _service.getAll();

    if (mounted) {
      setState(() {
        _all = data;
        _applyFilters(); // Aplica filtros iniciales
        _isLoading = false;
      });
    }
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
/// Imagen a la izquierda, datos a la derecha.
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  /// Convierte el valor interno del precio en símbolos visuales.
  /// 'low' → $   'mid' → $$   'high' → $$$
  String get _priceLabel {
    switch (restaurant.priceRange) {
      case 'low':  return '\$';
      case 'mid':  return '\$\$';
      case 'high': return '\$\$\$';
      default:     return restaurant.priceRange;
    }
  }

  /// Widget placeholder para mostrar cuando falta la imagen.
  Widget _placeholder() {
    return Container(
      width: 110,
      height: 110,
      color: Colors.grey[300],
      child: Icon(Icons.restaurant_outlined,
          color: Colors.grey[600], size: 40),
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

          // ── Imagen del restaurante ────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            child: restaurant.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => _placeholder(),
                  )
                : _placeholder(),
          ),


          // ── Información del restaurante ───────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Tipo de cocina
                  Row(children: [
                    const Icon(Icons.restaurant_menu_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(restaurant.cuisine,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),

                                    // Rating y rango de precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Estrellas y número
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

                      // Badge de precio ($, $$, $$$)
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}