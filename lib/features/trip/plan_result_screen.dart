import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../reservations/reservations_service.dart';

/// Muestra el itinerario generado por IA simulada localmente.
class PlanResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const PlanResultScreen({super.key, required this.args});

  @override
  State<PlanResultScreen> createState() => _PlanResultScreenState();
}

class _PlanResultScreenState extends State<PlanResultScreen> {
  bool _isSaving = false;
  bool _saved = false;

  // ── Getters ──────────────────────────────────────────────────────────
  String get _destinationName => widget.args['destination_name'] ?? 'Destino';
  String? get _destinationId => widget.args['destination_id'];
  String get _budget => widget.args['budget'] ?? '0';
  String get _type => widget.args['type'] ?? 'Cultural';
  DateTime? get _startDate => widget.args['start_date'] as DateTime?;
  DateTime? get _endDate => widget.args['end_date'] as DateTime?;
  int get _travelers => widget.args['travelers'] ?? 1;
  List<String> get _activities =>
      List<String>.from(widget.args['activities'] ?? []);
  String get _city => widget.args['city'] ?? '';
  String get _country => widget.args['country'] ?? '';

  int get _numDays {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 3;
  }

  /// Costo estimado por día dividiendo el presupuesto total entre los días
  double get _budgetPerDay {
    final total = double.tryParse(_budget) ?? 0;
    return _numDays > 0 ? total / _numDays : 0;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ── LÓGICA IA SIMULADA ──────────────────────────────────────────────

  /// Títulos de cada día según estilo de viaje
  final Map<String, List<String>> _dayTitles = {
    'Cultural': ['Exploración histórica', 'Arte y tradición', 'Día de museos', 'Patrimonio local'],
    'Aventura': ['Actividades al aire libre', 'Exploración extrema', 'Naturaleza salvaje', 'Adrenalina máxima'],
    'Relax': ['Bienestar y descanso', 'Spa y naturaleza', 'Tarde tranquila', 'Día libre'],
    'Gastronómico': ['Sabores locales', 'Tour de mercados', 'Cocina gourmet', 'Cenas especiales'],
    'Familiar': ['Diversión en familia', 'Juegos y parques', 'Paseo familiar', 'Experiencias compartidas'],
  };

  /// Actividades por franja horaria según estilo
  Map<String, List<String>> get _timeSlots {
    const map = {
      'Cultural': {
        'morning': ['Visita al centro histórico', 'Recorrido por monumentos', 'Tour guiado al amanecer'],
        'afternoon': ['Museo de arte local', 'Barrios tradicionales', 'Galería de arte contemporáneo'],
        'evening': ['Cena típica de la región', 'Espectáculo cultural', 'Plaza central al atardecer'],
      },
      'Aventura': {
        'morning': ['Senderismo en la montaña', 'Rafting en el río', 'Escalada en roca'],
        'afternoon': ['Rappel y tirolesa', 'Exploración de cuevas', 'Ciclismo de montaña'],
        'evening': ['Fogata y estrellas', 'Campamento base', 'Cena en la naturaleza'],
      },
      'Relax': {
        'morning': ['Yoga al amanecer', 'Meditación en la playa', 'Desayuno gourmet lento'],
        'afternoon': ['Spa y masajes', 'Piscina y lectura', 'Caminata tranquila'],
        'evening': ['Atardecer con cóctel', 'Cena romántica', 'Baño termal nocturno'],
      },
      'Gastronómico': {
        'morning': ['Mercado local y degustación', 'Desayuno típico tradicional', 'Tour de café y cacao'],
        'afternoon': ['Clase de cocina local', 'Almuerzo en restaurante top', 'Visita a viñedo o hacienda'],
        'evening': ['Cena de chef reconocido', 'Maridaje de vinos', 'Postre en café histórico'],
      },
      'Familiar': {
        'morning': ['Parque temático o zoo', 'Actividades interactivas', 'Desayuno buffet en familia'],
        'afternoon': ['Playa o piscina familiar', 'Juegos al aire libre', 'Taller de manualidades'],
        'evening': ['Cena familiar temática', 'Show o espectáculo', 'Helados y paseo nocturno'],
      },
    };
    return Map<String, List<String>>.from(
      (map[_type] ?? map['Cultural']!).map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ),
    );
  }

  /// Construye el itinerario completo con franjas horarias
  List<Map<String, dynamic>> _buildItinerary() {
    final dayTitles = _dayTitles[_type] ?? _dayTitles['Cultural']!;
    final slots = _timeSlots;
    final acts = List<String>.from(_activities);
    final List<Map<String, dynamic>> days = [];

    for (int i = 0; i < _numDays; i++) {
      // Distribuye actividades reales del destino en la mañana
      final List<String> realActs = [];
      if (acts.isNotEmpty) {
        final perDay = (acts.length / _numDays).ceil().clamp(1, 3);
        final start = (i * perDay).clamp(0, acts.length);
        final end = ((i + 1) * perDay).clamp(0, acts.length);
        if (start < acts.length) realActs.addAll(acts.sublist(start, end));
      }

      days.add({
        'day': 'Día ${i + 1}',
        'date': _startDate != null
            ? _formatDate(_startDate!.add(Duration(days: i)))
            : '',
        'title': dayTitles[i % dayTitles.length],
        // Franja mañana: usa actividades reales del destino si las hay
        'morning': realActs.isNotEmpty
            ? realActs.map((a) => a[0].toUpperCase() + a.substring(1)).join(', ')
            : slots['morning']![i % slots['morning']!.length],
        'afternoon': slots['afternoon']![i % slots['afternoon']!.length],
        'evening': slots['evening']![i % slots['evening']!.length],
        'budget': _budgetPerDay,
      });
    }
    return days;
  }

  /// Recomendaciones finales según estilo y destino
  List<Map<String, String>> get _recommendations {
    final Map<String, List<Map<String, String>>> recs = {
      'Cultural': [
        {'icon': '🎫', 'text': 'Compra entradas de museos con anticipación'},
        {'icon': '🗺️', 'text': 'Contratar un guía local enriquece la experiencia'},
        {'icon': '📷', 'text': 'Lleva cámara — hay mucho que fotografiar'},
      ],
      'Aventura': [
        {'icon': '🥾', 'text': 'Lleva calzado resistente e impermeable'},
        {'icon': '🧴', 'text': 'Protector solar y repelente son esenciales'},
        {'icon': '💧', 'text': 'Hidratación constante durante actividades físicas'},
      ],
      'Relax': [
        {'icon': '📵', 'text': 'Desconéctate del trabajo para aprovechar al máximo'},
        {'icon': '🛏️', 'text': 'Reserva con anticipación hoteles con spa'},
        {'icon': '🌅', 'text': 'Los amaneceres y atardeceres son imperdibles'},
      ],
      'Gastronómico': [
        {'icon': '🍽️', 'text': 'Reserva en restaurantes top con mínimo 1 semana'},
        {'icon': '💬', 'text': 'Pregunta a los locales por los mejores escondites'},
        {'icon': '🌶️', 'text': 'Atrévete a probar platillos desconocidos'},
      ],
      'Familiar': [
        {'icon': '🎒', 'text': 'Lleva snacks y agua para los niños siempre'},
        {'icon': '🏥', 'text': 'Ten a mano el seguro médico viajero'},
        {'icon': '🗓️', 'text': 'Planea descansos entre actividades para los más pequeños'},
      ],
    };
    return recs[_type] ?? recs['Cultural']!;
  }

  // ── GUARDAR RESERVA ─────────────────────────────────────────────────
  Future<void> _saveReservation() async {
    if (_destinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Este plan no tiene destino vinculado'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No hay fechas para guardar'),
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

  // ── BUILD ────────────────────────────────────────────────────────────
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

            // ── Título ──────────────────────────────────────────────────
            Text('Viaje a $_destinationName',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold)),
            if (_city.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$_city, $_country',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 14)),
              ),
            const SizedBox(height: 14),

            // ── Chips resumen ───────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(icon: Icons.attach_money, text: '\$$_budget USD'),
                _Chip(icon: Icons.explore, text: _type),
                _Chip(
                    icon: Icons.people,
                    text: '$_travelers viajero${_travelers > 1 ? 's' : ''}'),
                if (_startDate != null)
                  _Chip(
                      icon: Icons.calendar_today,
                      text:
                          '${_formatDate(_startDate)} → ${_formatDate(_endDate)}'),
                _Chip(
                    icon: Icons.schedule,
                    text: '$_numDays día${_numDays > 1 ? 's' : ''}'),
                _Chip(
                    icon: Icons.savings_outlined,
                    text:
                        '~\$${_budgetPerDay.toStringAsFixed(0)}/día'),
              ],
            ),

            const SizedBox(height: 30),

            // ── Header Itinerario ───────────────────────────────────────
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

            // ── Tarjetas de días ────────────────────────────────────────
            ...itinerary.map((day) => _DayCard(
                  day: day['day']!,
                  date: day['date']!,
                  title: day['title']!,
                  morning: day['morning']!,
                  afternoon: day['afternoon']!,
                  evening: day['evening']!,
                  budgetPerDay: day['budget'] as double,
                )),

            const SizedBox(height: 30),

            // ── Recomendaciones IA ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.auto_awesome,
                        color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text('Recomendaciones de la IA',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent)),
                  ]),
                  const SizedBox(height: 14),
                  ..._recommendations.map((rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec['icon']!,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(rec['text']!,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── Botón guardar ───────────────────────────────────────────
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
                onPressed: _saved || _isSaving ? null : _saveReservation,
              ),
            ),

            if (_saved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Ver mis reservas'),
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.reservations),
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

// ── COMPONENTES ─────────────────────────────────────────────────────────────

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
  final String day, date, title, morning, afternoon, evening;
  final double budgetPerDay;

  const _DayCard({
    required this.day,
    required this.date,
    required this.title,
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.budgetPerDay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header del día
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent)),
                if (date.isNotEmpty)
                  Text(date,
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                if (budgetPerDay > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '~\$${budgetPerDay.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const Divider(height: 20),

            // Franja mañana
            _TimeSlot(
              icon: Icons.wb_sunny_outlined,
              label: 'Mañana',
              color: Colors.orange,
              text: morning,
            ),
            const SizedBox(height: 10),

            // Franja tarde
            _TimeSlot(
              icon: Icons.wb_cloudy_outlined,
              label: 'Tarde',
              color: Colors.blue,
              text: afternoon,
            ),
            const SizedBox(height: 10),

            // Franja noche
            _TimeSlot(
              icon: Icons.nights_stay_outlined,
              label: 'Noche',
              color: Colors.indigo,
              text: evening,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String text;

  const _TimeSlot({
    required this.icon,
    required this.label,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
