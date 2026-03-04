import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';

/// Pantalla de notificaciones — RF-08 (alertas de precio) + RF-09 (notificaciones IA).
/// Lee reservas reales del usuario desde Supabase y genera alertas dinámicas.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Listas de notificaciones por categoría
  List<_NotifItem> _reservationNotifs = [];
  List<_NotifItem> _priceNotifs = [];
  List<_NotifItem> _aiNotifs = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Carga reservas del usuario y construye las notificaciones dinámicamente
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Trae reservas del usuario con el nombre del destino
      final response = await _supabase
          .from('reservations')
          .select('id, start_date, end_date, status, travelers, destinations(name, country)')
          .eq('user_id', userId)
          .order('start_date', ascending: true)
          .limit(10);

      final now = DateTime.now();
      final List<_NotifItem> reservNotifs = [];
      final List<_NotifItem> priceAlerts = [];
      final List<_NotifItem> aiSuggestions = [];

      for (final r in response as List) {
        final destName = r['destinations']?['name'] ?? 'Destino';
        final country = r['destinations']?['country'] ?? '';
        final startDate = DateTime.tryParse(r['start_date'] ?? '');
        final status = r['status'] ?? 'pending';
        final travelers = r['travelers'] ?? 1;

        if (startDate != null) {
          final daysUntil = startDate.difference(now).inDays;

          // Notificación de reserva próxima (menos de 30 días)
          if (daysUntil >= 0 && daysUntil <= 30) {
            reservNotifs.add(_NotifItem(
              icon: Icons.flight_takeoff,
              color: AppColors.accent,
              title: '¡Tu viaje a $destName se acerca!',
              subtitle: daysUntil == 0
                  ? '¡Hoy es el día! Buen viaje 🎉'
                  : 'Faltan $daysUntil días · $travelers viajero${travelers > 1 ? 's' : ''}',
              time: _formatDate(startDate),
              isUrgent: daysUntil <= 3,
            ));
          } else if (daysUntil > 30) {
            reservNotifs.add(_NotifItem(
              icon: Icons.bookmark_outlined,
              color: Colors.blue,
              title: 'Reserva confirmada — $destName',
              subtitle: 'Tienes $daysUntil días para prepararte · Estado: $status',
              time: _formatDate(startDate),
              isUrgent: false,
            ));
          }

          // Alerta de precio simulada (RF-08) para destinos con más de 15 días
          if (daysUntil > 15) {
            final discount = (daysUntil % 3 == 0) ? 12 : (daysUntil % 2 == 0) ? 8 : 5;
            priceAlerts.add(_NotifItem(
              icon: Icons.local_offer_outlined,
              color: Colors.green,
              title: 'Precio actualizado — $destName, $country',
              subtitle: 'Los vuelos bajaron un $discount% esta semana. ¡Aprovecha!',
              time: 'Hace ${(daysUntil % 5) + 1}h',
              isUrgent: discount >= 10,
            ));
          }

          // Recomendación IA (RF-09) basada en destino
          aiSuggestions.add(_NotifItem(
            icon: Icons.auto_awesome,
            color: Colors.purple,
            title: 'Recomendación IA para $destName',
            subtitle: _getAiTip(country, daysUntil),
            time: 'IA · Personalizado',
            isUrgent: false,
          ));
        }
      }

      // Si no hay reservas, muestra sugerencias generales
      if (aiSuggestions.isEmpty) {
        aiSuggestions.addAll([
          _NotifItem(
            icon: Icons.auto_awesome,
            color: Colors.purple,
            title: 'Planea tu próxima aventura',
            subtitle: 'La IA puede crear un itinerario personalizado en segundos.',
            time: 'IA · General',
            isUrgent: false,
          ),
          _NotifItem(
            icon: Icons.explore_outlined,
            color: Colors.teal,
            title: 'Destinos de temporada',
            subtitle: 'Cartagena, Bali y Tokio son tendencia este mes.',
            time: 'IA · Tendencias',
            isUrgent: false,
          ),
        ]);
      }

      if (mounted) {
        setState(() {
          _reservationNotifs = reservNotifs;
          _priceNotifs = priceAlerts;
          _aiNotifs = aiSuggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Tip de IA según país y días restantes
  String _getAiTip(String country, int daysUntil) {
    if (daysUntil <= 7) {
      return 'Confirma tu alojamiento y descarga mapas offline de $country.';
    } else if (daysUntil <= 30) {
      return 'Buen momento para gestionar el seguro de viaje para $country.';
    } else {
      return 'Empieza a investigar la cultura y gastronomía de $country.';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  int get _totalNotifs =>
      _reservationNotifs.length + _priceNotifs.length + _aiNotifs.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
        actions: [
          // Badge con total de notificaciones
          if (_totalNotifs > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_totalNotifs',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppColors.accent,
              child: _totalNotifs == 0
                  ? _emptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ── Reservas próximas ──────────────────────
                        if (_reservationNotifs.isNotEmpty) ...[
                          _SectionHeader(
                              icon: Icons.flight_takeoff,
                              title: 'Tus viajes',
                              count: _reservationNotifs.length),
                          ..._reservationNotifs
                              .map((n) => _NotifCard(item: n)),
                          const SizedBox(height: 8),
                        ],

                        // ── Alertas de precio (RF-08) ──────────────
                        if (_priceNotifs.isNotEmpty) ...[
                          _SectionHeader(
                              icon: Icons.local_offer_outlined,
                              title: 'Alertas de precio',
                              count: _priceNotifs.length),
                          ..._priceNotifs.map((n) => _NotifCard(item: n)),
                          const SizedBox(height: 8),
                        ],

                        // ── Recomendaciones IA (RF-09) ─────────────
                        if (_aiNotifs.isNotEmpty) ...[
                          _SectionHeader(
                              icon: Icons.auto_awesome,
                              title: 'Recomendaciones IA',
                              count: _aiNotifs.length),
                          ..._aiNotifs.map((n) => _NotifCard(item: n)),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Sin notificaciones por ahora',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Cuando hagas una reserva aparecerá aquí',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}

// ── MODELOS Y COMPONENTES ────────────────────────────────────────────────────

/// Datos de una notificación individual
class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final bool isUrgent;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isUrgent,
  });
}

/// Encabezado de sección con ícono, título y contador
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

/// Tarjeta individual de notificación
class _NotifCard extends StatelessWidget {
  final _NotifItem item;
  const _NotifCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: item.isUrgent ? 4 : 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      // Borde de urgencia si el viaje es en menos de 3 días
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: item.isUrgent
              ? Border.all(color: Colors.orange.shade300, width: 1.5)
              : null,
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: item.color.withOpacity(0.12),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (item.isUrgent)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('¡Pronto!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          subtitle: Column( 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Text(item.subtitle,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13, height: 1.3)),
              const SizedBox(height: 4),
              Text(item.time,
                  style: TextStyle(
                      color:
                      Colors.grey[400], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
