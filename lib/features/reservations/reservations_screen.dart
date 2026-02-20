import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'reservations_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _service = ReservationsService();
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final data = await _service.getUserReservations();
    if (mounted) {
      setState(() {
        _reservations = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelReservation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('¿Estás seguro de que deseas cancelar esta reserva?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Sí, cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.cancelReservation(id);
      _loadReservations();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReservations,
              child: _reservations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reservations.length,
                      itemBuilder: (context, index) {
                        return _ReservationCard(
                          reservation: _reservations[index],
                          formatDate: _formatDate,
                          onCancel: _cancelReservation,
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No tienes reservas aún',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Explora destinos y crea tu primer plan de viaje',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.explore, color: Colors.white),
            label: const Text('Explorar destinos',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pushNamed(context, '/explore'),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final String Function(String?) formatDate;
  final Function(String) onCancel;

  const _ReservationCard({
    required this.reservation,
    required this.formatDate,
    required this.onCancel,
  });

  Color get _statusColor {
    switch (reservation['status']) {
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  String get _statusLabel {
    switch (reservation['status']) {
      case 'confirmed': return 'Confirmada';
      case 'cancelled': return 'Cancelada';
      default: return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = reservation['destinations'] as Map<String, dynamic>?;
    final destName = dest?['name'] ?? 'Destino';
    final destCity = dest?['city'] ?? '';
    final destCountry = dest?['country'] ?? '';
    final imageUrl = dest?['image_url'] ?? '';
    final travelers = reservation['travelers'] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported)),
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
                      child: Text(destName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_statusLabel,
                          style: TextStyle(
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ],
                ),

                if (destCity.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$destCity, $destCountry',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ]),
                ],

                const SizedBox(height: 12),

                Row(children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    '${formatDate(reservation['start_date'])} → ${formatDate(reservation['end_date'])}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ]),

                const SizedBox(height: 6),

                Row(children: [
                  const Icon(Icons.people_outline,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text('$travelers viajero${travelers > 1 ? 's' : ''}'),
                ]),

                if (reservation['notes'] != null &&
                    reservation['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(reservation['notes'],
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ),
                    ],
                  ),
                ],

                if (reservation['status'] == 'pending') ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: Colors.red),
                      label: const Text('Cancelar',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => onCancel(reservation['id']),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
