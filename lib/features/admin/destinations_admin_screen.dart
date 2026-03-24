import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../explore/models/destination_model.dart';
import 'admin_service.dart';

/// Gestión de destinos — CRUD completo con métricas y animaciones premium.
class DestinationsAdminScreen extends StatefulWidget {
  final bool embedded;
  const DestinationsAdminScreen({super.key, this.embedded = false});

  @override
  State<DestinationsAdminScreen> createState() =>
      _DestinationsAdminScreenState();
}

class _DestinationsAdminScreenState extends State<DestinationsAdminScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _admin = AdminService();
  List<Destination> _destinations = [];
  List<Destination> _filtered = [];
  bool _isLoading = true;
  String _query = '';
  String _categoryFilter = 'all';
  late AnimationController _animationController;

  final List<String> _categories = [
    'all',
    'Urbano',
    'Playa',
    'Naturaleza',
    'Histórico',
    'Montaña',
    'Cultural'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _admin.getAllDestinations();
    if (mounted) {
      setState(() {
        _destinations = data;
        _applyFilters();
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    }
  }

  void _applyFilters() {
    final q = _query.toLowerCase();
    setState(() {
      _filtered = _destinations.where((d) {
        // Filtro por categoría
        if (_categoryFilter != 'all' && d.category != _categoryFilter) {
          return false;
        }
        // Filtro por búsqueda
        if (q.isNotEmpty) {
          return d.title.toLowerCase().contains(q) ||
              d.country.toLowerCase().contains(q) ||
              d.city.toLowerCase().contains(q);
        }
        return true;
      }).toList();
    });
  }

  void _onSearch(String q) {
    _query = q;
    _applyFilters();
  }

  Future<void> _delete(Destination d) async {
    final ok = await _confirmDialog(
      title: 'Eliminar destino',
      message: '¿Eliminar "${d.title}"? Esta acción no se puede deshacer.\n\n'
          'Se eliminarán todas las reservas asociadas a este destino.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!ok) return;
    try {
      await _admin.deleteDestination(d.id);
      _load();
      _showSnack('🗑️ Destino eliminado correctamente', success: true);
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}',
          success: false);
    }
  }

  void _openForm({Destination? destination}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DestinationFormDialog(
        destination: destination,
        onSave: (d) async {
          try {
            if (destination == null) {
              await _admin.createDestination(d);
              _showSnack('✨ Destino "${d.title}" creado', success: true);
            } else {
              await _admin.updateDestination(d);
              _showSnack('📝 Destino "${d.title}" actualizado', success: true);
            }
            _load();
          } catch (e) {
            _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}',
                success: false);
          }
        },
      ),
    );
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF111D2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(destructive ? Icons.warning_amber : Icons.info_outline,
                    color: destructive ? AppColors.error : AppColors.accent),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(message,
                style: TextStyle(color: Colors.white.withOpacity(0.6))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar',
                    style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      destructive ? AppColors.error : AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Barra de herramientas premium
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Búsqueda
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        onChanged: _onSearch,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar destino...',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3), fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.white.withOpacity(0.4), size: 18),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: Colors.white.withOpacity(0.4), size: 16),
                                  onPressed: () {
                                    _query = '';
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filtro por categoría
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoryFilter,
                        icon: Icon(Icons.filter_list,
                            color: Colors.white.withOpacity(0.5), size: 18),
                        dropdownColor: const Color(0xFF111D2E),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (v) {
                          setState(() => _categoryFilter = v ?? 'all');
                          _applyFilters();
                        },
                        items: _categories.map((c) {
                          String label = c == 'all' ? 'Todas' : c;
                          return DropdownMenuItem(value: c, child: Text(label));
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contador
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filtered.length} / ${_destinations.length}',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón nuevo
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nuevo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _openForm(),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.place_outlined,
                              size: 48, color: Colors.white.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text('No hay destinos que coincidan',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          if (isWide) {
                            return FadeTransition(
                              opacity: _animationController,
                              child: _buildTable(),
                            );
                          }
                          return _buildCards();
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 50),
                _th('Destino', flex: 3),
                _th('País', flex: 2),
                _th('Categoría', flex: 2),
                _th('Rating', flex: 1),
                _th('Precio', flex: 2),
                const SizedBox(width: 100),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ..._filtered.map((d) => _DestinationRow(
                destination: d,
                onEdit: () => _openForm(destination: d),
                onDelete: () => _delete(d),
              )),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final d = _filtered[i];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111D2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: d.mainImage,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.white10,
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white30),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 3),
                    Text('${d.city}, ${d.country}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.accent, size: 18),
                onPressed: () => _openForm(destination: d),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 18),
                onPressed: () => _delete(d),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody();
    }
    return Scaffold(
      backgroundColor: const Color(0xFF070E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1520),
        title: const Text('Destinos Turísticos',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILA DE TABLA MEJORADA
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationRow extends StatefulWidget {
  final Destination destination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DestinationRow({
    required this.destination,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DestinationRow> createState() => _DestinationRowState();
}

class _DestinationRowState extends State<_DestinationRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFF111D2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: d.mainImage,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 38,
                  height: 38,
                  color: Colors.white10,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.white30, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                d.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(d.country,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  d.category,
                  style: const TextStyle(color: AppColors.accent, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(d.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${d.currency} ${d.priceMin.toInt()}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
            ),
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionBtn(
                    icon: Icons.edit_rounded,
                    color: AppColors.accent,
                    tooltip: 'Editar',
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 4),
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    tooltip: 'Eliminar',
                    onTap: widget.onDelete,
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM DIALOG MEJORADO
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationFormDialog extends StatefulWidget {
  final Destination? destination;
  final Future<void> Function(Destination) onSave;

  const _DestinationFormDialog({this.destination, required this.onSave});

  @override
  State<_DestinationFormDialog> createState() => _DestinationFormDialogState();
}

class _DestinationFormDialogState extends State<_DestinationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _previewImage = false;

  late final TextEditingController _name;
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _priceMin;
  late final TextEditingController _priceMax;
  late final TextEditingController _rating;
  late final TextEditingController _currency;
  late final TextEditingController _climate;
  late final TextEditingController _bestSeason;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  String _category = 'Urbano';

  final _categories = [
    'Urbano',
    'Playa',
    'Naturaleza',
    'Histórico',
    'Montaña',
    'Cultural'
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.destination;
    _name = TextEditingController(text: d?.title ?? '');
    _country = TextEditingController(text: d?.country ?? '');
    _city = TextEditingController(text: d?.city ?? '');
    _description = TextEditingController(text: d?.description ?? '');
    _imageUrl = TextEditingController(text: d?.mainImage ?? '');
    _priceMin = TextEditingController(
        text: d?.priceMin.toStringAsFixed(0) ?? '0');
    _priceMax = TextEditingController(
        text: d?.priceMax.toStringAsFixed(0) ?? '0');
    _rating = TextEditingController(text: d?.rating.toString() ?? '4.5');
    _currency = TextEditingController(text: d?.currency ?? 'USD');
    _climate = TextEditingController(text: d?.climate ?? '');
    _bestSeason = TextEditingController(text: d?.bestSeason ?? '');
    _lat = TextEditingController(text: d?.latitude.toString() ?? '0');
    _lng = TextEditingController(text: d?.longitude.toString() ?? '0');
    _category = d?.category ?? 'Urbano';
  }

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    _city.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _priceMin.dispose();
    _priceMax.dispose();
    _rating.dispose();
    _currency.dispose();
    _climate.dispose();
    _bestSeason.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final d = Destination(
      id: widget.destination?.id ?? '',
      title: _name.text.trim(),
      country: _country.text.trim(),
      city: _city.text.trim(),
      description: _description.text.trim(),
      mainImage: _imageUrl.text.trim(),
      gallery: widget.destination?.gallery ?? [],
      rating: double.tryParse(_rating.text) ?? 4.5,
      reviews: widget.destination?.reviews ?? 0,
      latitude: double.tryParse(_lat.text) ?? 0,
      longitude: double.tryParse(_lng.text) ?? 0,
      category: _category,
      priceMin: double.tryParse(_priceMin.text) ?? 0,
      priceMax: double.tryParse(_priceMax.text) ?? 0,
      currency: _currency.text.trim(),
      climate: _climate.text.trim(),
      bestSeason: _bestSeason.text.trim(),
    );

    await widget.onSave(d);
    if (mounted) Navigator.pop(context);
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.destination != null;

    return Dialog(
      backgroundColor: const Color(0xFF111D2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 640,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit
                          ? Icons.edit_rounded
                          : Icons.add_location_alt_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Editar destino' : 'Nuevo destino',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withOpacity(0.4)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section('INFORMACIÓN BÁSICA'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _Field(
                                  ctrl: _name,
                                  label: 'Nombre',
                                  required: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _Field(
                                  ctrl: _country,
                                  label: 'País',
                                  required: true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _Field(
                                  ctrl: _city,
                                  label: 'Ciudad',
                                  required: true)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categoría',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _category,
                                  dropdownColor: const Color(0xFF111D2E),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                  decoration: _inputDeco(),
                                  items: _categories
                                      .map((c) => DropdownMenuItem(
                                          value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) => setState(
                                      () => _category = v ?? _category),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Field(
                          ctrl: _description,
                          label: 'Descripción',
                          required: true,
                          maxLines: 3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(ctrl: _imageUrl,
                                label: 'URL de imagen principal'),
                          ),
                          const SizedBox(width: 8),
                          if (_imageUrl.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.preview,
                                  color: AppColors.accent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: const Color(0xFF111D2E),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    content: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _imageUrl.text,
                                        height: 300,
                                        width: 400,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image,
                                                size: 50,
                                                color: Colors.white30),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(_),
                                        child: Text('Cerrar',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5))),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _Section('PRECIOS'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _Field(
                                  ctrl: _priceMin,
                                  label: 'Precio mínimo',
                                  numeric: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _Field(
                                  ctrl: _priceMax,
                                  label: 'Precio máximo',
                                  numeric: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _Field(
                                  ctrl: _currency, label: 'Moneda')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _Section('UBICACIÓN Y CLIMA'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _Field(
                                  ctrl: _lat,
                                  label: 'Latitud',
                                  numeric: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _Field(
                                  ctrl: _lng,
                                  label: 'Longitud',
                                  numeric: true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child:
                                  _Field(ctrl: _climate, label: 'Clima')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _Field(
                                  ctrl: _bestSeason,
                                  label: 'Mejor temporada')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _Field(
                                  ctrl: _rating,
                                  label: 'Rating',
                                  numeric: true)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEdit ? 'Guardar cambios' : 'Crear destino'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.accent,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool required;
  final bool numeric;
  final int maxLines;

  const _Field({
    required this.ctrl,
    required this.label,
    this.required = false,
    this.numeric = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
              : null,
        ),
      ],
    );
  }
}