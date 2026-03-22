import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'admin_service.dart';

/// Gestión de reservas — el admin puede ver todas y cambiar su estado.
class ReservationsAdminScreen extends StatefulWidget {
  const ReservationsAdminScreen({super.key});

  @override
  State<ReservationsAdminScreen> createState() =>
      _ReservationsAdminScreenState();
}

class _ReservationsAdminScreenState extends State<ReservationsAdminScreen> {
  final AdminService _admin = AdminService();
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _admin.getAllReservations();
    if (mounted) {
      setState(() {
        _reservations = data;
        _applyFilter(_statusFilter);
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String status) {
    _statusFilter = status;
    setState(() {
      _filtered = status == 'all'
          ? _reservations
          : _reservations.where((r) => r['status'] == status).toList();
    });
  }

  Future<void> _changeStatus(Map<String, dynamic> reservation, String newStatus) async {
    try {
      await _admin.updateReservationStatus(reservation['id'], newStatus);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a $newStatus'),
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
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'confirmed': return 'Confirmada';
      case 'cancelled': return 'Cancelada';
      default: return 'Pendiente';
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    final date = DateTime.tryParse(d);
    if (date == null) return d;
    const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas')),
      body: Column(
        children: [
          // Filtros por estado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in [
                    {'key': 'all', 'label': 'Todas'},
                    {'key': 'pending', 'label': 'Pendientes'},
                    {'key': 'confirmed', 'label': 'Confirmadas'},
                    {'key': 'cancelled', 'label': 'Canceladas'},
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(item['label']!),
                        selected: _statusFilter == item['key'],
                        onSelected: (_) => _applyFilter(item['key']!),
                        selectedColor: AppColors.accent.withOpacity(0.15),
                        checkmarkColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: _statusFilter == item['key']
                              ? AppColors.accent
                              : null,
                          fontWeight: _statusFilter == item['key']
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Text('${_filtered.length} reservas',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ]),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No hay reservas'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final r = _filtered[i];
                            final dest = r['destinations'] as Map?;
                            final profile = r['profiles'] as Map?;
                            final status = r['status'] ?? 'pending';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            dest?['name'] ?? 'Destino',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: TextStyle(
                                              color: _statusColor(status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Usuario
                                    Row(children: [
                                      const Icon(Icons.person_outline,
                                          size: 14, color: AppColors.accent),
                                      const SizedBox(width: 6),
                                      Text(
                                        profile?['full_name'] ??
                                            profile?['email'] ??
                                            'Usuario',
                                        style: TextStyle(
                                            color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ]),
                                    const SizedBox(height: 4),

                                    // Fechas
                                    Row(children: [
                                      const Icon(Icons.calendar_month_outlined,
                                          size: 14, color: AppColors.accent),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_formatDate(r['start_date'])} → ${_formatDate(r['end_date'])}',
                                        style: TextStyle(
                                            color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ]),
                                    const SizedBox(height: 4),

                                    // Viajeros
                                    Row(children: [
                                      const Icon(Icons.people_outline,
                                          size: 14, color: AppColors.accent),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${r['travelers'] ?? 1} viajero${(r['travelers'] ?? 1) > 1 ? 's' : ''}',
                                        style: TextStyle(
                                            color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ]),

                                    // Botones de acción (solo si no está cancelada)
                                    if (status != 'cancelled') ...[
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        if (status != 'confirmed')
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.check_circle_outline,
                                                  size: 16, color: Colors.green),
                                              label: const Text('Confirmar',
                                                  style: TextStyle(
                                                      color: Colors.green, fontSize: 13)),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Colors.green),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10)),
                                              ),
                                              onPressed: () =>
                                                  _changeStatus(r, 'confirmed'),
                                            ),
                                          ),
                                        if (status != 'confirmed')
                                          const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.cancel_outlined,
                                                size: 16, color: Colors.red),
                                            label: const Text('Cancelar',
                                                style: TextStyle(
                                                    color: Colors.red, fontSize: 13)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.red),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () =>
                                                _changeStatus(r, 'cancelled'),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}