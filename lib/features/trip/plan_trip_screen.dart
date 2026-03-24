import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/loading_overlay.dart';
import '../explore/models/destination_model.dart';
import '../trip/services/trip_service.dart';
import '../trip/models/trip_model.dart';

class PlanTripScreen extends StatefulWidget {
  final Destination? preselectedDestination;

  const PlanTripScreen({super.key, this.preselectedDestination});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen>
    with SingleTickerProviderStateMixin {
  final _budgetController = TextEditingController();
  
  String _selectedType = 'Cultural';
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 1;
  late AnimationController _animationController;

  final List<String> _tripTypes = [
    'Cultural', 'Aventura', 'Relax', 'Gastronómico', 'Familiar'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? now.add(const Duration(days: 1))
          : (_startDate?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 2))),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar';
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _generatePlan() async {
    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un presupuesto')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona las fechas del viaje')),
      );
      return;
    }

    final trip = Trip(
      destinationName: widget.preselectedDestination?.title ?? 'Destino libre',
      destinationId: widget.preselectedDestination?.id,
      type: _selectedType,
      travelers: _travelers,
      budget: double.parse(_budgetController.text),
      startDate: _startDate!,
      endDate: _endDate!,
    );

    LoadingOverlay.show(context, message: 'Planificando tu viaje ideal...');

    try {
      final tripId = await TripService().createTrip(trip);
      LoadingOverlay.hide();
      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.planResult,
        arguments: {
          'trip_id': tripId,
          'trip': trip,
        },
      );
    } catch (e) {
      LoadingOverlay.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando viaje: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dest = widget.preselectedDestination;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070E17) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Planear viaje con IA',
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
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimationConfiguration.staggeredList(
                position: 0,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accent.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Diseña tu próximo viaje',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Cuéntanos tus ideas y nuestra IA creará un plan personalizado.',
                                      style: TextStyle(
                                        color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Destino
              AnimationConfiguration.staggeredList(
                position: 1,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111D2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.place, color: AppColors.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dest != null
                                      ? '${dest.title}, ${dest.country}'
                                      : 'Destino libre',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  dest != null ? dest.category : 'Planificación general',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (dest != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('✓ Seleccionado',
                                  style: TextStyle(color: AppColors.accent, fontSize: 11)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Fechas
              AnimationConfiguration.staggeredList(
                position: 2,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Row(
                      children: [
                        Expanded(
                          child: _DateCardPremium(
                            label: 'Llegada',
                            value: _formatDate(_startDate),
                            icon: Icons.flight_land,
                            onTap: () => _pickDate(true),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateCardPremium(
                            label: 'Salida',
                            value: _formatDate(_endDate),
                            icon: Icons.flight_takeoff,
                            onTap: () => _pickDate(false),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 12),
                AnimationConfiguration.staggeredList(
                  position: 3,
                  child: SlideAnimation(
                    verticalOffset: 30,
                    child: FadeInAnimation(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule, color: AppColors.accent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_endDate!.difference(_startDate!).inDays} noches',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Viajeros
              AnimationConfiguration.staggeredList(
                position: 4,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111D2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.people_outline, color: AppColors.accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Viajeros', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          IconButton(
                            onPressed: _travelers > 1 ? () => setState(() => _travelers--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: _travelers > 1 ? AppColors.accent : Colors.grey,
                          ),
                          Text('$_travelers',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: _travelers < 20 ? () => setState(() => _travelers++) : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: _travelers < 20 ? AppColors.accent : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Presupuesto
              AnimationConfiguration.staggeredList(
                position: 5,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111D2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.attach_money, color: AppColors.accent, size: 20),
                          ),
                          labelText: 'Presupuesto total (USD)',
                          hintText: 'Ej: 1500',
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Estilo de viaje
              AnimationConfiguration.staggeredList(
                position: 6,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estilo de viaje',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _tripTypes.map((type) {
                            final isSelected = _selectedType == type;
                            return FilterChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedType = type),
                              backgroundColor: Colors.transparent,
                              selectedColor: AppColors.accent,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.accent,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.accent
                                    : isDark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.grey[300]!,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón generar
              AnimationConfiguration.staggeredList(
                position: 7,
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Container(
                      width: double.infinity,
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
                        icon: const Icon(Icons.auto_awesome, color: Colors.white),
                        label: const Text(
                          'Generar plan con IA',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _generatePlan,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE CARD PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _DateCardPremium extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _DateCardPremium({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != 'Seleccionar';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111D2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasValue
                ? AppColors.accent
                : isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200]!,
          ),
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
            Icon(icon, color: hasValue ? AppColors.accent : Colors.grey[400], size: 20),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                  color: hasValue
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey[500],
                )),
          ],
        ),
      ),
    );
  }
}