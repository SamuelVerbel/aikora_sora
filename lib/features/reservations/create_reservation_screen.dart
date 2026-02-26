import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../explore/models/destination_model.dart';
import 'reservations_service.dart';

/// Pantalla/modal para crear una nueva reserva sobre un destino.
/// Se abre como bottomSheet desde destination_detail_screen.
class CreateReservationScreen extends StatefulWidget {
  final Destination destination;

  const CreateReservationScreen({
    super.key,
    required this.destination,
  });

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState
    extends State<CreateReservationScreen> {
  final _service = ReservationsService();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ── Selector de fecha ────────────────────────────────────────────
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? (_startDate ?? now).add(const Duration(days: 3)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        // Si la fecha de fin es anterior a la nueva de inicio, la resetea
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  // ── Calcula noches entre las dos fechas ──────────────────────────
  int get _nights {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  // ── Precio estimado total ────────────────────────────────────────
  double get _estimatedTotal {
    if (widget.destination.priceMin <= 0) return 0;
    return widget.destination.priceMin * _nights * _travelers;
  }

  // ── Validación y envío ───────────────────────────────────────────
  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona las fechas de entrada y salida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_nights < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La salida debe ser al menos 1 día después'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.createReservation(
        destinationId: widget.destination.id,
        startDate: _startDate!,
        endDate: _endDate!,
        travelers: _travelers,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // true = creada con éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('¡Reserva creada exitosamente!'),
            ]),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Formato legible de fecha ─────────────────────────────────────
  String _formatDate(DateTime date) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // Handle visual del bottomSheet
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              'Reservar en ${widget.destination.title}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.destination.city}, ${widget.destination.country}',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // ── Fechas ──────────────────────────────────────────────
            const Text('Fechas del viaje',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                // Fecha de entrada
                Expanded(
                  child: _DateButton(
                    label: 'Entrada',
                    date: _startDate != null
                        ? _formatDate(_startDate!)
                        : null,
                    icon: Icons.flight_land_outlined,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                // Fecha de salida
                Expanded(
                  child: _DateButton(
                    label: 'Salida',
                    date: _endDate != null
                        ? _formatDate(_endDate!)
                        : null,
                    icon: Icons.flight_takeoff_outlined,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),

            // Resumen de noches
            if (_nights > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.nights_stay_outlined,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      '$_nights noche${_nights != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ── Viajeros ────────────────────────────────────────────
            const Text('Viajeros',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.people_outline,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$_travelers viajero${_travelers != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ]),
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: _travelers > 1
                          ? AppColors.accent
                          : Colors.grey[300],
                      onPressed: _travelers > 1
                          ? () => setState(() => _travelers--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: _travelers < 20
                          ? AppColors.accent
                          : Colors.grey[300],
                      onPressed: _travelers < 20
                          ? () => setState(() => _travelers++)
                          : null,
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Notas opcionales ────────────────────────────────────
            const Text('Notas (opcional)',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Solicitudes especiales, preferencias...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            // ── Precio estimado ─────────────────────────────────────
            if (_estimatedTotal > 0)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimado total',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '${widget.destination.currency} ${_estimatedTotal.toInt()}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // ── Botón confirmar ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirmar reserva',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar para los botones de fecha ──────────────────────
class _DateButton extends StatelessWidget {
  final String label;
  final String? date;
  final IconData icon;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasDate
              ? AppColors.accent.withOpacity(0.07)
              : Colors.grey[50],
          border: Border.all(
            color: hasDate ? AppColors.accent : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon,
                  size: 16,
                  color:
                      hasDate ? AppColors.accent : Colors.grey[400]),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: hasDate
                          ?
                    AppColors.accent
                          : Colors.grey[500],
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text(
              date ?? 'Seleccionar',
              style: TextStyle(
                fontSize: 13,
                color: hasDate ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

