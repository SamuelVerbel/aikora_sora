import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_overlay.dart';
import 'reservations_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  final _service = ReservationsService();
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadReservations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    LoadingOverlay.show(context, message: 'Cargando tus reservas...');
    final data = await _service.getUserReservations();
    if (mounted) {
      setState(() {
        _reservations = data;
        _isLoading = false;
      });
      _animationController.forward();
    }
    LoadingOverlay.hide();
  }

  Future<void> _cancelReservation(String id, String destName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Cancelar reserva', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '¿Cancelar tu reserva en $destName?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      LoadingOverlay.show(context, message: 'Cancelando reserva...');
      await _service.cancelReservation(id);
      await _loadReservations();
      LoadingOverlay.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Reserva cancelada correctamente'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070E17) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mis Reservas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? const Color(0xFF0B1520) : Colors.white,
                isDark ? const Color(0xFF0F1A2A) : Colors.grey[50]!,
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _loadReservations,
              color: AppColors.accent,
              child: _reservations.isEmpty
                  ? _EmptyState()
                  : AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reservations.length,
                        itemBuilder: (context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50,
                              child: FadeInAnimation(
                                child: _ReservationCardPremium(
                                  reservation: _reservations[index],
                                  formatDate: _formatDate,
                                  onCancel: (id) => _cancelReservation(
                                    id,
                                    (_reservations[index]['destinations'] as Map?)?['name'] ?? 'destino',
                                  ),
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage_outlined,
            size: 100,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No tienes reservas aún',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora destinos y crea tu primer plan de viaje',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.explore, color: Colors.white),
              label: const Text(
                'Explorar destinos',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pushNamed(context, '/explore'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESERVATION CARD PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _ReservationCardPremium extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final String Function(String?) formatDate;
  final Function(String) onCancel;
  final bool isDark;

  const _ReservationCardPremium({
    required this.reservation,
    required this.formatDate,
    required this.onCancel,
    required this.isDark,
  });

  Color get _statusColor {
    switch (reservation['status']) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (reservation['status']) {
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Pendiente';
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
    final status = reservation['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111D2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.grey.withOpacity(0.1),
                  child: const Icon(Icons.image_not_supported, size: 40),
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
                      child: Text(
                        destName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                if (destCity.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '$destCity, $destCountry',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 12),

                // Fechas
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month_outlined,
                          size: 14, color: AppColors.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${formatDate(reservation['start_date'])} → ${formatDate(reservation['end_date'])}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Viajeros
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.people_outline,
                          size: 14, color: AppColors.accent),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$travelers viajero${travelers > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),

                if (reservation['notes'] != null &&
                    reservation['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline,
                            size: 14, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reservation['notes'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancelar reserva'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
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