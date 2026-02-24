import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../reservations/reservations_service.dart';

class PlanResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const PlanResultScreen({super.key, required this.args});

  @override
  State<PlanResultScreen> createState() => _PlanResultScreenState();
}

class _PlanResultScreenState extends State<PlanResultScreen> {
  bool _isSaving = false;
  bool _saved = false;

  String get _destinationName =>
      widget.args['destination_name'] ?? 'Destino';
  String? get _destinationId => widget.args['destination_id'];
  String get _budget => widget.args['budget'] ?? '0';
  String get _type => widget.args['type'] ?? 'Cultural';
  DateTime? get _startDate => widget.args['start_date'] as DateTime?;
  DateTime? get _endDate => widget.args['end_date'] as DateTime?;
  int get _travelers => widget.args['travelers'] ?? 1;
  List<String> get _activities =>
      List<String>.from(widget.args['activities'] ?? []);

  int get _numDays {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 3;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // IA local: distribuye actividades reales entre los días
  List<Map<String, String>> _buildItinerary() {
    final Map<String, List<String>> titles = {
      'Cultural': ['Exploración histórica', 'Arte y tradición', 'Día de museos', 'Patrimonio local'],
      'Aventura': ['Actividades al aire libre', 'Exploración extrema', 'Naturaleza salvaje', 'Adrenalina máxima'],
      'Relax': ['Bienestar y descanso', 'Spa y naturaleza', 'Tarde tranquila', 'Día libre'],
      'Gastronómico': ['Sabores locales', 'Tour de mercados', 'Cocina gourmet', 'Cenas especiales'],
      'Familiar': ['Diversión en familia', 'Juegos y parques', 'Paseo familiar', 'Experiencias compartidas'],
    };
    final dayTitles = titles[_type] ?? titles['Cultural']!;
    final acts = List<String>.from(_activities);
    final List<Map<String, String>> days = [];

    for (int i = 0; i < _numDays; i++) {
      final List<String> dayActs = [];
      if (acts.isNotEmpty) {
        final perDay = (acts.length / _numDays).ceil();
        final start = (i * perDay).clamp(0, acts.length);
        final end = ((i + 1) * perDay).clamp(0, acts.length);
        if (start < acts.length) dayActs.addAll(acts.sublist(start, end));
      }

      final description = dayActs.isNotEmpty
          ? dayActs
              .map((a) => a[0].toUpperCase() + a.substring(1))
              .join(' · ')
          : _genericDesc(i);

      days.add({
        'day': 'Día ${i + 1}',
        'date': _startDate != null
            ? _formatDate(_startDate!.add(Duration(days: i)))
            : '',
        'title': dayTitles[i % dayTitles.length],
        'description': description,
      });
    }
    return days;
  }

  String _genericDesc(int day) {
    final Map<String, List<String>> descs = {
      'Cultural': [
        'Visita al centro histórico y gastronomía local.',
        'Exploración de barrios y arquitectura tradicional.',
        'Recorrido cultural y compras de artesanías.',
      ],
      'Aventura': [
        'Deportes al aire libre y exploración de la zona.',
        'Senderismo y contacto con la naturaleza.',
        'Actividades extremas en entornos naturales.',
      ],
      'Relax': [
        'Amanecer tranquilo, spa y descanso.',
        'Paseo lento, lectura y gastronomía sin prisa.',
        'Piscina y atardecer en lugar especial.',
      ],
      'Gastronómico': [
        'Mercado local, almuerzo gourmet y cena especial.',
        'Tour por cocinas locales y degustación.',
        'Clase de cocina local y cena de cierre.',
      ],
      'Familiar': [
        'Parques y restaurantes familiares.',
        'Paseo por zonas seguras y divertidas.',
        'Compras, souvenirs y actividades para todos.',
      ],
    };
    final list = descs[_type] ?? descs['Cultural']!;
    return list[day % list.length];
  }

  Future<void> _saveReservation() async {
    if (_destinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Este plan no tiene un destino vinculado a la base de datos'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No hay fechas para guardar la reserva'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ReservationsService().createReservation(
        destinationId: _destinationId!,
        startDate: _startDate!,
        endDate: _endDate!,
        travelers: _travelers,
        notes: 'Plan IA · Estilo: $_type · Presupuesto: \$$_budget USD',
      );
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Reserva guardada exitosamente'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = _buildItinerary();

    return Scaffold(
      appBar: AppBar(title: const Text('Tu plan personalizado ✨')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Viaje a $_destinationName',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // Chips resumen
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(icon: Icons.attach_money, text: '\$$_budget USD'),
                _Chip(icon: Icons.explore, text: _type),
                _Chip(
                    icon: Icons.people,
                    text:
                        '$_travelers viajero${_travelers > 1 ? 's' : ''}'),
                if (_startDate != null)
                  _Chip(
                      icon: Icons.calendar_today,
                      text:
                          '${_formatDate(_startDate)} → ${_formatDate(_endDate)}'),
                _Chip(
                    icon: Icons.schedule,
                    text: '$_numDays día${_numDays > 1 ? 's' : ''}'),
              ],
            ),

            const SizedBox(height: 30),

            Row(children: [
              const Text('Itinerario generado por IA',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('LOCAL',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Basado en actividades reales del destino',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 20),

            // Días dinámicos
            ...itinerary
                .map((day) => _DayCard(
                      day: day['day']!,
                      date: day['date']!,
                      title: day['title']!,
                      description: day['description']!,
                    ))
                ,

            const SizedBox(height: 30),

            // Botón guardar reserva
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: Icon(
                    _saved ? Icons.check_circle : Icons.bookmark_border,
                    color: Colors.white),
                label: Text(
                    _saved ? 'Reserva guardada ✓' : 'Guardar como reserva',
                    style: const TextStyle(
                        fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _saved ? Colors.green : AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed:
                    _saved || _isSaving ? null : _saveReservation,
              ),
            ),

            if (_saved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Ver mis reservas'),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.reservations),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String day, date, title, description;
  const _DayCard(
      {required this.day,
      required this.date,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(day,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent)),
            if (date.isNotEmpty)
              Text(date,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(description,
              style: TextStyle(color: Colors.grey[600], height: 1.5)),
        ]),
      ),
    );
  }
}
