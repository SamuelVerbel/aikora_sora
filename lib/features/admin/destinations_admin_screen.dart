import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import './../explore/models/destination_model.dart';
import 'admin_service.dart';

/// Pantalla de gestión de destinos turísticos.
/// CRUD completo: crear, ver, editar, eliminar, cambiar imagen.
class DestinationsAdminScreen extends StatefulWidget {
  const DestinationsAdminScreen({super.key});

  @override
  State<DestinationsAdminScreen> createState() =>
      _DestinationsAdminScreenState();
}

class _DestinationsAdminScreenState extends State<DestinationsAdminScreen> {
  final AdminService _admin = AdminService();
  List<Destination> _destinations = [];
  List<Destination> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _admin.getAllDestinations();
    if (mounted) {
      setState(() {
        _destinations = data;
        _filtered = data;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _destinations.where((d) =>
        d.title.toLowerCase().contains(query) ||
        d.country.toLowerCase().contains(query) ||
        d.city.toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> _delete(Destination dest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar destino'),
        content: Text('¿Eliminar "${dest.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _admin.deleteDestination(dest.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${dest.title} eliminado'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openForm({Destination? destination}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationFormScreen(
          destination: destination,
          onSaved: _load,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destinos turísticos'),
        actions: [
          IconButton(
            tooltip: 'Nuevo destino',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar destino...',
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text('${_filtered.length} destinos',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('No hay destinos'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Crear destino', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                              onPressed: () => _openForm(),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _DestinationTile(
                            destination: _filtered[i],
                            onEdit: () => _openForm(destination: _filtered[i]),
                            onDelete: () => _delete(_filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo destino', style: TextStyle(color: Colors.white)),
        onPressed: () => _openForm(),
      ),
    );
  }
}

// ── Tile de destino ───────────────────────────────────────────────────────────

class _DestinationTile extends StatelessWidget {
  final Destination destination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DestinationTile({
    required this.destination,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Row(
        children: [
          // Imagen
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: destination.mainImage,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 90,
                height: 90,
                color: Colors.grey[200],
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(destination.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${destination.city}, ${destination.country}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(destination.category,
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.amber, size: 13),
                    Text(' ${destination.rating}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ),
          // Acciones
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 20),
                onPressed: onEdit,
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: onDelete,
                tooltip: 'Eliminar',
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Formulario crear / editar destino ─────────────────────────────────────────

class DestinationFormScreen extends StatefulWidget {
  final Destination? destination;
  final VoidCallback onSaved;

  const DestinationFormScreen({
    super.key,
    this.destination,
    required this.onSaved,
  });

  @override
  State<DestinationFormScreen> createState() => _DestinationFormScreenState();
}

class _DestinationFormScreenState extends State<DestinationFormScreen> {
  final AdminService _admin = AdminService();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  late final TextEditingController _title;
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _priceMin;
  late final TextEditingController _priceMax;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _tags;
  late final TextEditingController _activities;
  late final TextEditingController _amenities;

  String _category = 'general';
  String _climate = 'Templado';
  String _currency = 'USD';

  final List<String> _categories = [
    'general', 'playa', 'montaña', 'ciudad', 'cultura', 'aventura', 'naturaleza'
  ];
  final List<String> _climates = ['Cálido', 'Frío', 'Templado', 'Tropical'];
  final List<String> _currencies = ['USD', 'EUR', 'COP', 'MXN', 'ARS'];

  bool get _isEditing => widget.destination != null;

  @override
  void initState() {
    super.initState();
    final d = widget.destination;
    _title = TextEditingController(text: d?.title ?? '');
    _country = TextEditingController(text: d?.country ?? '');
    _city = TextEditingController(text: d?.city ?? '');
    _description = TextEditingController(text: d?.description ?? '');
    _imageUrl = TextEditingController(text: d?.mainImage ?? '');
    _priceMin = TextEditingController(text: d?.priceMin.toStringAsFixed(0) ?? '');
    _priceMax = TextEditingController(text: d?.priceMax.toStringAsFixed(0) ?? '');
    _latitude = TextEditingController(text: d?.latitude.toString() ?? '');
    _longitude = TextEditingController(text: d?.longitude.toString() ?? '');
    _tags = TextEditingController(text: d?.tags.join(', ') ?? '');
    _activities = TextEditingController(text: d?.activities.join(', ') ?? '');
    _amenities = TextEditingController(text: d?.amenities.join(', ') ?? '');
    _category = d?.category ?? 'general';
    _climate = d?.climate.isNotEmpty == true ? d!.climate : 'Templado';
    _currency = d?.currency ?? 'USD';
  }

  @override
  void dispose() {
    for (final c in [
      _title, _country, _city, _description, _imageUrl,
      _priceMin, _priceMax, _latitude, _longitude,
      _tags, _activities, _amenities
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _splitField(String value) =>
      value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final destination = Destination(
        id: widget.destination?.id ?? '',
        title: _title.text.trim(),
        country: _country.text.trim(),
        city: _city.text.trim(),
        description: _description.text.trim(),
        mainImage: _imageUrl.text.trim(),
        gallery: widget.destination?.gallery ?? [],
        rating: widget.destination?.rating ?? 0,
        reviews: widget.destination?.reviews ?? 0,
        latitude: double.tryParse(_latitude.text) ?? 0,
        longitude: double.tryParse(_longitude.text) ?? 0,
        category: _category,
        amenities: _splitField(_amenities.text),
        priceMin: double.tryParse(_priceMin.text) ?? 0,
        priceMax: double.tryParse(_priceMax.text) ?? 0,
        currency: _currency,
        climate: _climate,
        bestSeason: widget.destination?.bestSeason ?? '',
        activities: _splitField(_activities.text),
        tags: _splitField(_tags.text),
        durationMin: widget.destination?.durationMin ?? 3,
        durationMax: widget.destination?.durationMax ?? 7,
      );

      if (_isEditing) {
        await _admin.updateDestination(destination);
      } else {
        await _admin.createDestination(destination);
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '${destination.title} actualizado ✓'
                : '${destination.title} creado ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar destino' : 'Nuevo destino'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // Preview imagen
            if (_imageUrl.text.isNotEmpty)
              Container(
                height: 180,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: _imageUrl.text,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image, size: 40)),
                  ),
                ),
              ),

            _section('Información básica'),
            _field(_title, 'Nombre del destino *', required: true),
            _field(_country, 'País *', required: true),
            _field(_city, 'Ciudad *', required: true),
            _field(_description, 'Descripción *', required: true, maxLines: 4),

            _section('Imagen principal'),
            _field(
              _imageUrl,
              'URL de imagen principal *',
              required: true,
              hint: 'https://ejemplo.com/imagen.jpg',
              onChanged: (_) => setState(() {}),
            ),

            _section('Categoría y clima'),
            _dropdown('Categoría', _category, _categories,
                (v) => setState(() => _category = v!)),
            const SizedBox(height: 12),
            _dropdown('Clima', _climate, _climates,
                (v) => setState(() => _climate = v!)),

            _section('Precios'),
            Row(children: [
              Expanded(child: _field(_priceMin, 'Precio mínimo', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field(_priceMax, 'Precio máximo', keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            _dropdown('Moneda', _currency, _currencies,
                (v) => setState(() => _currency = v!)),

            _section('Coordenadas GPS'),
            Row(children: [
              Expanded(child: _field(_latitude, 'Latitud', hint: 'Ej: 4.7110', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field(_longitude, 'Longitud', hint: 'Ej: -74.0721', keyboardType: TextInputType.number)),
            ]),

            _section('Detalles adicionales'),
            _field(_activities, 'Actividades (separadas por coma)',
                hint: 'senderismo, buceo, cultura'),
            const SizedBox(height: 12),
            _field(_amenities, 'Servicios (separados por coma)',
                hint: 'wifi, piscina, restaurante'),
            const SizedBox(height: 12),
            _field(_tags, 'Tags (separados por coma)',
                hint: 'playa, familia, romantico'),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: Icon(
                  _isEditing ? Icons.save_outlined : Icons.add_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _isSaving ? 'Guardando...' : (_isEditing ? 'Actualizar destino' : 'Crear destino'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _save,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
            color: AppColors.accent)),
  );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      );
}