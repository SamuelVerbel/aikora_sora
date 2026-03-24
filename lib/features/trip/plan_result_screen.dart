import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/loading_overlay.dart';
import '../reservations/reservations_service.dart';
import '../trip/repositories/trip_repository.dart';

/// Muestra el itinerario generado por IA con diseño premium.
/// RF-19: Compartir itinerario por enlace
/// RF-20: Colaboración en tiempo real con Supabase Realtime
class PlanResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const PlanResultScreen({super.key, required this.args});

  @override
  State<PlanResultScreen> createState() => _PlanResultScreenState();
}

class _PlanResultScreenState extends State<PlanResultScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>>? _aiItinerary;
  bool _loadingAI = true;
  bool _isSaving = false;
  bool _saved = false;
  bool _usedRemoteAI = false;
  late AnimationController _animationController;

  // RF-20 — Realtime
  final TripRepository _tripRepo = TripRepository();
  RealtimeChannel? _realtimeChannel;
  List<Map<String, dynamic>> _collaborators = [];

  // ── Getters ──────────────────────────────────────────────────────────
  String get _destinationName =>
      widget.args['destination_name'] ?? widget.args['trip']?.destinationName ?? 'Destino';
  String? get _destinationId =>
      widget.args['destination_id'] ?? widget.args['trip']?.destinationId;
  String get _budget =>
      widget.args['budget']?.toString() ?? widget.args['trip']?.budget.toString() ?? '0';
  String get _type =>
      widget.args['type'] ?? widget.args['trip']?.type ?? 'Cultural';
  DateTime? get _startDate =>
      widget.args['start_date'] as DateTime? ?? widget.args['trip']?.startDate;
  DateTime? get _endDate =>
      widget.args['end_date'] as DateTime? ?? widget.args['trip']?.endDate;
  int get _travelers =>
      widget.args['travelers'] ?? widget.args['trip']?.travelers ?? 1;
  List<String> get _activities =>
      List<String>.from(widget.args['activities'] ?? []);
  String get _city => widget.args['city'] ?? '';
  String get _country => widget.args['country'] ?? '';
  String? get _tripId => widget.args['trip_id'] as String?;

  int get _numDays {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 3;
  }

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadAIPlan();
    if (_tripId != null) {
      _loadCollaborators();
      _subscribeRealtime();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_realtimeChannel != null) {
      _tripRepo.unsubscribe(_realtimeChannel!);
    }
    super.dispose();
  }

  // ── RF-20: Realtime ────────────────────────────────────────────────────────

  Future<void> _loadCollaborators() async {
    if (_tripId == null) return;
    final list = await _tripRepo.getCollaborators(_tripId!);
    if (mounted) setState(() => _collaborators = list);
  }

  void _subscribeRealtime() {
    if (_tripId == null) return;
    _realtimeChannel = _tripRepo.subscribeToTrip(
      tripId: _tripId!,
      onUpdate: (payload) {
        if (!mounted) return;
        final updatedItinerary = payload['itinerary'];
        if (updatedItinerary != null) {
          setState(() {
            _aiItinerary = List<Map<String, dynamic>>.from(updatedItinerary);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.people, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Un colaborador actualizó el itinerario'),
                ],
              ),
              backgroundColor: Colors.purple,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  void _showInviteCollaborator() {
    if (_tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero guarda el plan como reserva'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InviteCollaboratorSheet(
        emailCtrl: emailCtrl,
        tripId: _tripId!,
        onInvited: () {
          _loadCollaborators();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Itinerario local (fallback) ────────────────────────────────────────────

  final Map<String, List<String>> _dayTitles = {
    'Cultural': ['Exploración histórica', 'Arte y tradición', 'Día de museos', 'Patrimonio local'],
    'Aventura': ['Actividades al aire libre', 'Exploración extrema', 'Naturaleza salvaje', 'Adrenalina máxima'],
    'Relax': ['Bienestar y descanso', 'Spa y naturaleza', 'Tarde tranquila', 'Día libre'],
    'Gastronómico': ['Sabores locales', 'Tour de mercados', 'Cocina gourmet', 'Cenas especiales'],
    'Familiar': ['Diversión en familia', 'Juegos y parques', 'Paseo familiar', 'Experiencias compartidas'],
  };

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

  List<Map<String, dynamic>> _buildItinerary() {
    final dayTitles = _dayTitles[_type] ?? _dayTitles['Cultural']!;
    final slots = _timeSlots;
    final acts = List<String>.from(_activities);
    final List<Map<String, dynamic>> days = [];

    for (int i = 0; i < _numDays; i++) {
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

  // ── Guardar reserva ───────────────────────────────────────────────────────

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

    LoadingOverlay.show(context, message: 'Guardando tu plan...');

    try {
      await ReservationsService().createReservation(
        destinationId: _destinationId!,
        startDate: _startDate!,
        endDate: _endDate!,
        travelers: _travelers,
        notes: 'Plan IA · Estilo: $_type · Presupuesto: \$$_budget USD',
      );
      LoadingOverlay.hide();
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('✅ Reserva guardada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      LoadingOverlay.hide();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _loadAIPlan() async {
    LoadingOverlay.show(context, message: 'Generando tu plan personalizado...');
    try {
      final response = await ReservationsService().generateAIPlan(widget.args);
      LoadingOverlay.hide();
      if (!mounted) return;
      setState(() {
        _aiItinerary = List<Map<String, dynamic>>.from(response['days'] ?? []);
        _usedRemoteAI = true;
        _loadingAI = false;
      });
      _animationController.forward();
    } catch (e) {
      LoadingOverlay.hide();
      debugPrint('IA remota falló, usando IA local: $e');
      if (!mounted) return;
      setState(() {
        _aiItinerary = null;
        _usedRemoteAI = false;
        _loadingAI = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingAI) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF070E17) : const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Generando tu plan personalizado...',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'La IA está trabajando para ti ✨',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final itinerary = _aiItinerary ?? _buildItinerary();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070E17) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0B1520) : Colors.white,
        title: const Text(
          'Tu plan personalizado ✨',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_tripId != null)
            IconButton(
              tooltip: 'Invitar colaborador',
              icon: Stack(
                children: [
                  const Icon(Icons.people_outline),
                  if (_collaborators.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_collaborators.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showInviteCollaborator,
            ),
          IconButton(
            tooltip: 'Compartir itinerario',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _tripId != null
                        ? 'Enlace: aikora.app/trip/$_tripId'
                        : 'Guarda el plan primero para compartirlo',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header premium
              AnimationConfiguration.staggeredList(
                position: 0,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _destinationName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_city.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$_city, $_country',
                              style: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Chips resumen premium
              AnimationConfiguration.staggeredList(
                position: 1,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _PremiumChip(
                          icon: Icons.attach_money,
                          text: '\$$_budget USD',
                          color: AppColors.accent,
                        ),
                        _PremiumChip(
                          icon: Icons.explore,
                          text: _type,
                          color: Colors.orange,
                        ),
                        _PremiumChip(
                          icon: Icons.people,
                          text: '$_travelers viajero${_travelers > 1 ? 's' : ''}',
                          color: Colors.blue,
                        ),
                        if (_startDate != null)
                          _PremiumChip(
                            icon: Icons.calendar_today,
                            text: '${_formatDate(_startDate)} → ${_formatDate(_endDate)}',
                            color: Colors.green,
                          ),
                        _PremiumChip(
                          icon: Icons.schedule,
                          text: '$_numDays día${_numDays > 1 ? 's' : ''}',
                          color: Colors.purple,
                        ),
                        _PremiumChip(
                          icon: Icons.savings_outlined,
                          text: '~\$${_budgetPerDay.toStringAsFixed(0)}/día',
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Badge colaboradores
              if (_collaborators.isNotEmpty) ...[
                const SizedBox(height: 12),
                AnimationConfiguration.staggeredList(
                  position: 2,
                  child: SlideAnimation(
                    verticalOffset: 30,
                    child: FadeInAnimation(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people, color: Colors.purple, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${_collaborators.length} colaborador${_collaborators.length > 1 ? 'es' : ''} en este viaje',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Header itinerario
              AnimationConfiguration.staggeredList(
                position: 3,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Row(
                      children: [
                        const Text(
                          'Itinerario generado por IA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _usedRemoteAI ? 'IA' : 'LOCAL',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimationConfiguration.staggeredList(
                position: 4,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Text(
                      _usedRemoteAI
                          ? 'Plan generado por IA en la nube'
                          : 'Basado en actividades reales del destino',
                      style: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tarjetas de días
              ...itinerary.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                return AnimationConfiguration.staggeredList(
                  position: 5 + index,
                  child: SlideAnimation(
                    verticalOffset: 30,
                    child: FadeInAnimation(
                      child: _DayCardPremium(
                        day: day['day']!,
                        date: day['date']!,
                        title: day['title']!,
                        morning: day['morning']!,
                        afternoon: day['afternoon']!,
                        evening: day['evening']!,
                        budgetPerDay: (day['budget'] as num).toDouble(),
                        isDark: isDark,
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 28),

              // Recomendaciones IA
              AnimationConfiguration.staggeredList(
                position: 5 + itinerary.length,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withOpacity(0.08),
                            AppColors.accent.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Recomendaciones de la IA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ..._recommendations.map((rec) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rec['icon']!, style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        rec['text']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                          color: isDark ? Colors.white70 : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              AnimationConfiguration.staggeredList(
                position: 6 + itinerary.length,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.people_outline, color: AppColors.accent),
                            label: const Text(
                              'Planear en grupo',
                              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.accent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _showInviteCollaborator,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _saved ? null : AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _saved
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppColors.accent.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton.icon(
                              icon: Icon(
                                _saved ? Icons.check_circle : Icons.bookmark_border,
                                color: Colors.white,
                              ),
                              label: Text(
                                _saved ? 'Reserva guardada ✓' : 'Guardar como reserva',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _saved ? Colors.green : Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _saved || _isSaving ? null : _saveReservation,
                            ),
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
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTES PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _PremiumChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCardPremium extends StatelessWidget {
  final String day, date, title, morning, afternoon, evening;
  final double budgetPerDay;
  final bool isDark;

  const _DayCardPremium({
    required this.day,
    required this.date,
    required this.title,
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.budgetPerDay,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDark ? const Color(0xFF111D2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (budgetPerDay > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '~\$${budgetPerDay.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            _TimeSlotPremium(
              icon: Icons.wb_sunny_outlined,
              label: 'Mañana',
              color: Colors.orange,
              text: morning,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _TimeSlotPremium(
              icon: Icons.wb_cloudy_outlined,
              label: 'Tarde',
              color: Colors.blue,
              text: afternoon,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _TimeSlotPremium(
              icon: Icons.nights_stay_outlined,
              label: 'Noche',
              color: Colors.indigo,
              text: evening,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotPremium extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String text;
  final bool isDark;

  const _TimeSlotPremium({
    required this.icon,
    required this.label,
    required this.color,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INVITE COLLABORATOR SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _InviteCollaboratorSheet extends StatefulWidget {
  final TextEditingController emailCtrl;
  final String tripId;
  final VoidCallback onInvited;

  const _InviteCollaboratorSheet({
    required this.emailCtrl,
    required this.tripId,
    required this.onInvited,
  });

  @override
  State<_InviteCollaboratorSheet> createState() => _InviteCollaboratorSheetState();
}

class _InviteCollaboratorSheetState extends State<_InviteCollaboratorSheet> {
  final TripRepository _tripRepo = TripRepository();
  bool _isInviting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111D2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Invitar colaborador',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'El colaborador podrá ver y editar este itinerario en tiempo real.',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: widget.emailCtrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Email del colaborador',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.accent),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isInviting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  _isInviting ? 'Enviando...' : 'Invitar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isInviting
                    ? null
                    : () async {
                        final email = widget.emailCtrl.text.trim();
                        if (email.isEmpty) return;
                        setState(() => _isInviting = true);
                        try {
                          await _tripRepo.inviteCollaborator(
                            tripId: widget.tripId,
                            email: email,
                          );
                          if (mounted) {
                            widget.onInvited();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invitación enviada a $email'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al invitar: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isInviting = false);
                        }
                      },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}