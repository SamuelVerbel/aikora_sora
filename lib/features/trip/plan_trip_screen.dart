import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../explore/models/destination_model.dart';
import '../trip/services/trip_service.dart';
import '../trip/models/trip_model.dart';

/// Pantalla donde el usuario ingresa sus preferencias (fechas, presupuesto,
/// estilo de viaje y número de personas) antes de pasárselas a la "IA".
class PlanTripScreen extends StatefulWidget {
  // Si el usuario llega desde la pantalla de detalle, este campo trae la info del lugar
  final Destination? preselectedDestination;

  const PlanTripScreen({super.key, this.preselectedDestination});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _budgetController = TextEditingController();
  
  // Valores por defecto del formulario
  String _selectedType = 'Cultural';
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 1;

  final List<String> _tripTypes = [
    'Cultural', 'Aventura', 'Relax', 'Gastronómico', 'Familiar'
  ];

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  /// Abre el calendario nativo para seleccionar fecha de llegada o salida.
  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // Si es salida, sugerimos 2 días después. Si es llegada, 1 día después.
      initialDate: isStart
          ? now.add(const Duration(days: 1))
          : (_startDate?.add(const Duration(days: 1)) ??
              now.add(const Duration(days: 2))),
      firstDate: now, // No permite planear viajes en el pasado
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        // Aplica el color principal de nuestra app al calendario de Flutter
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Validar: si la fecha final quedó antes que la nueva inicial, bórrala
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// Convierte el objeto DateTime a un formato legible (Ej: "14 Feb 2026")
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ingresa un presupuesto')));
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona las fechas del viaje')));
      return;
    }

    final trip = Trip(
      destinationName:
          widget.preselectedDestination?.title ?? 'Destino libre',
      destinationId: widget.preselectedDestination?.id,
      type: _selectedType,
      travelers: _travelers,
      budget: double.parse(_budgetController.text),
      startDate: _startDate!,
      endDate: _endDate!,
    );

    try {
      final tripId = await TripService().createTrip(trip);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando viaje: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.preselectedDestination;

    return Scaffold(
      appBar: AppBar(title: const Text('Planear viaje con IA')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Diseña tu próximo viaje ✨',
                  style:
                      TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'Cuéntanos tus ideas y nuestra IA creará un plan personalizado.',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 30),

              // ── 📍 Destino (Solo lectura, viene heredado) ───────────────
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading:
                      const Icon(Icons.place, color: AppColors.accent),
                  title: Text(
                    dest != null
                        ? '${dest.title}, ${dest.country}'
                        : 'Destino libre',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(dest != null
                      ? dest.category
                      : 'Planificación general'),
                  trailing: dest != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('✓ Seleccionado',
                              style: TextStyle(
                                  color: AppColors.accent, fontSize: 12)),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              // ── 📅 Selector de Fechas ──────────────────────────────────
              Row(children: [
                Expanded(
                  child: _DateCard(
                    label: 'Llegada',
                    value: _formatDate(_startDate),
                    icon: Icons.flight_land,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateCard(
                    label: 'Salida',
                    value: _formatDate(_endDate),
                    icon: Icons.flight_takeoff,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ]),

              // ── ⏳ Cálculo automático de duración ──────────────────────
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_endDate!.difference(_startDate!).inDays} noches',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── 👥 Contador de Viajeros ────────────────────────────────
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.people_outline,
                        color: AppColors.accent),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text('Viajeros',
                            style:
                                TextStyle(fontWeight: FontWeight.w600))),
                    IconButton(
                      onPressed: _travelers > 1
                          ? () => setState(() => _travelers--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.accent,
                    ),
                    Text('$_travelers',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _travelers < 20
                          ? () => setState(() => _travelers++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.accent,
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // ── 💰 Presupuesto ─────────────────────────────────────────
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.attach_money,
                          color: AppColors.accent),
                      labelText: 'Presupuesto total (USD)',
                      hintText: 'Ej: 1500',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 🎒 Estilo de viaje (Filtros) ───────────────────────────
              const Text('Estilo de viaje',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tripTypes.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedType = type),
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // ── 🔥 Botón Generar ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome,
                      color: Colors.white),
                  label: const Text('Generar plan con IA',
                      style: TextStyle(
                          fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _generatePlan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget auxiliar para los selectores de fecha
class _DateCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
