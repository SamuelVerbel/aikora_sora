// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Para obtener la ubicación GPS
import '../explore/models/destination_model.dart';
import '../explore/data/destinations_repository.dart';
import '../explore/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Pantalla Explorar.
/// Muestra TODOS los destinos y permite buscar por texto,
/// filtrar por categoría y ordenar por cercanía usando el GPS del usuario.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Conexión con Supabase para traer los datos
  final _repository = DestinationsRepository();
  
  // Guardamos TODOS los destinos aquí para no llamar a la BD en cada búsqueda
  List<Destination> _allDestinations = [];
  
  // Lista que realmente se muestra en pantalla (resultado de los filtros)
  List<Destination> _filtered = [];
  
  bool _isLoading = true; // Controla el spinner inicial
  String _query = '';     // Texto actual de la barra de búsqueda

  // ── Variables de Geolocalización y Filtros ───────────────────────
  Position? _userPosition;       // Coordenadas actuales del usuario
  bool _sortByDistance = false;  // ¿Está activo el ordenamiento por GPS?
  bool _loadingLocation = false; // Controla el spinner del botón GPS
  String? _categoryFilter;       // Categoría seleccionada (ej. 'playa')

  @override
  void initState() {
    super.initState();
    // addPostFrameCallback asegura que el widget ya está construido antes de 
    // intentar leer los argumentos de la ruta (ModalRoute).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Leemos si el usuario viene del Home habiendo tocado una categoría
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['category'] != null) {
        _categoryFilter = args['category'];
      }
      
      // Una vez capturados los filtros, cargamos los datos
      _loadDestinations();
    });
  }

  /// Trae la lista completa de destinos desde Supabase 1 sola vez.
  Future<void> _loadDestinations() async {
    setState(() => _isLoading = true);
    final data = await _repository.getDestinations();
    
    if (mounted) {
      setState(() {
        _allDestinations = data;
        _applyFilters(); // Aplica filtros iniciales (si venía con categoría)
        _isLoading = false;
      });
    }
  }

  /// Motor principal de filtrado y ordenamiento.
  /// Se llama cada vez que el usuario escribe, borra, activa o desactiva un filtro.
  void _applyFilters() {
    // 1. Empezamos con la lista completa
    List<Destination> result = List.from(_allDestinations);

    // 2. Filtro de Búsqueda de texto (Buscador)
    if (_query.isNotEmpty) {
      result = result.where((d) =>
        d.title.toLowerCase().contains(_query.toLowerCase()) ||
        d.country.toLowerCase().contains(_query.toLowerCase()) ||
        d.city.toLowerCase().contains(_query.toLowerCase())
      ).toList();
    }

    // 3. Filtro de Categoría (si se tocó un botón en el Home)
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      result = result.where((d) =>
        d.category.toLowerCase().contains(_categoryFilter!) ||
        // Verifica si la categoría está dentro del arreglo de tags
        (d.tags.any((t) => t.toLowerCase().contains(_categoryFilter!)))
      ).toList();
    }

    // 4. Ordenamiento por Distancia (si el usuario tocó el icono de GPS)
    if (_sortByDistance && _userPosition != null) {
      result.sort((a, b) {
        // Calcula distancia desde el usuario al destino A
        final distA = (a.longitude != null)
            ? LocationService.distanceInKm(
                _userPosition!.latitude, _userPosition!.longitude,
                a.latitude, a.longitude)
            : double.infinity; // Si no tiene coordenadas, lo manda al final
            
        // Calcula distancia desde el usuario al destino B
        final distB = (b.longitude != null)
            ? LocationService.distanceInKm(
                _userPosition!.latitude, _userPosition!.longitude,
                b.latitude, b.longitude)
            : double.infinity;
            
        // Compara distancias para ordenarlas de menor a mayor
        return distA.compareTo(distB);
      });
    }

    // 5. Actualizamos la lista visible
    _filtered = result;
  }

  /// Se ejecuta cada vez que el usuario teclea en el buscador.
  void _onSearch(String value) {
    setState(() {
      _query = value;
      _applyFilters(); // Re-calcula la lista al instante
    });
  }

  /// Activa o desactiva el ordenamiento por GPS.
  Future<void> _toggleNearMe() async {
    // Si ya estaba activo, lo desactivamos
    if (_sortByDistance) {
      setState(() {
        _sortByDistance = false;
        _applyFilters();
      });
      return;
    }

    setState(() => _loadingLocation = true);

    // Pide permisos de GPS y obtiene la ubicación actual
    final position = await LocationService.getCurrentPosition();

    // Si el usuario denegó permisos o el GPS está apagado
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

    // Si obtuvo coordenadas con éxito
    if (mounted) {
      setState(() {
        _userPosition = position;
        _sortByDistance = true;
        _loadingLocation = false;
        _applyFilters(); // Reordena la lista basándose en las nuevas coordenadas
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
      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Explorar destinos'),
        centerTitle: true,
        actions: [
          // Botón del GPS en la barra superior
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
                      // Cambia de color si está activo
                      color: _sortByDistance ? AppColors.accent : null,
                    ),
                  ),
          ),
        ],
      ),
      
      // ── Cuerpo Principal ──────────────────────────────────────────────────
      body: Column(
        children: [
          // 1. Buscador (Búsqueda de texto)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar ciudad o país',
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                // Muestra botón "X" solo si hay texto escrito
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _applyFilters(); // Recalcula sin texto
                          });
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),

          // 2. Chips (Pastillas) de estado activo (GPS o Categoría)
          // Se muestran dinámicamente solo si el usuario activó algún filtro.
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

          // 3. Texto contador de resultados
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  // Lógica ternaria para manejar singular/plural correctamente
                  '${_filtered.length} destino${_filtered.length != 1 ? 's' : ''} encontrado${_filtered.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),

          // 4. Lista de resultados (con soporte de scroll)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _emptyState() // Pantalla vacía si la búsqueda no dio resultados
                    : RefreshIndicator(
                        onRefresh: _loadDestinations,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => DestinationCard(
                            destination: _filtered[i],
                            // Pasamos la posición del usuario a la tarjeta 
                            // para que calcule la etiqueta de "X km de ti"
                            userPosition: _userPosition,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SUB-WIDGETS LOCALES
  // ──────────────────────────────────────────────────────────────────────────

  /// Diseño que se muestra cuando la búsqueda/filtro devuelve 0 resultados.
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
              // Botón de escape: borra todos los filtros de golpe
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

// ────────────────────────────────────────────────────────────────────────────
// COMPONENTES REUTILIZABLES
// ────────────────────────────────────────────────────────────────────────────

/// Pastilla (Chip) que indica qué filtro está activo. 
/// Tiene una X para eliminarlo.
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

/// Tarjeta grande de destino para la lista vertical de resultados.
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
    // Lógica para mostrar la etiqueta "A X km de ti".
    // Solo se calcula si el usuario activó el GPS y tenemos sus coordenadas.
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
      elevation: 4, // Sombra ligera
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagen ──────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
          ),
          // ── Información inferior ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Título del destino
                    Expanded(
                      child: Text(destination.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    
                    // Badge de distancia calculada (solo visible si GPS activo)
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
                // Ubicación (Ciudad, País)
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text('${destination.city}, ${destination.country}',
                      style: TextStyle(color: Colors.grey[600])),
                ]),

                const SizedBox(height: 8),
                // Descripción truncada a máximo 2 líneas
                Text(destination.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),

                const SizedBox(height: 10),
                // Estrellas y Reseñas
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${destination.rating} (${destination.reviews} reseñas)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ]),

                const SizedBox(height: 14),
                // Botón Ver Más
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
                      // Pasamos el objeto destino completo a la siguiente pantalla
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
