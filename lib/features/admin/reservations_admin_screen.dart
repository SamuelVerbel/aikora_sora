import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'admin_service.dart';

/// Gestión de reservas — con métricas, filtros avanzados y acciones rápidas.
class ReservationsAdminScreen extends StatefulWidget {
  final bool embedded;
  const ReservationsAdminScreen({super.key, this.embedded = false});

  @override
  State<ReservationsAdminScreen> createState() =>
      _ReservationsAdminScreenState();
}

class _ReservationsAdminScreenState extends State<ReservationsAdminScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _admin = AdminService();
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _statusFilter = 'all';
  String _searchQuery = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _admin.getAllReservations();
    if (mounted) {
      setState(() {
        _reservations = data;
        _applyFilters();
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _reservations.where((r) {
        // Filtro por estado
        if (_statusFilter != 'all' && r['status'] != _statusFilter) {
          return false;
        }
        // Filtro por búsqueda
        if (_searchQuery.isNotEmpty) {
          final destName = (r['destinations'] as Map?)?['name'] ?? '';
          final userName = (r['profiles'] as Map?)?['full_name'] ?? '';
          final userEmail = (r['profiles'] as Map?)?['email'] ?? '';
          return destName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              userEmail.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        return true;
      }).toList();
    });
  }

  Future<void> _changeStatus(Map<String, dynamic> r, String newStatus) async {
    final isConfirm = newStatus == 'confirmed';
    final isCancel = newStatus == 'cancelled';
    final destName = (r['destinations'] as Map?)?['name'] ?? 'destino';
    final userName = (r['profiles'] as Map?)?['full_name'] ?? 'usuario';

    String title;
    String message;
    Color color;

    if (isConfirm) {
      title = 'Confirmar reserva';
      message = '¿Confirmar la reserva de $userName para $destName?\n\n'
          'El usuario recibirá una notificación de confirmación.';
      color = AppColors.success;
    } else if (isCancel) {
      title = 'Cancelar reserva';
      message = '¿Cancelar la reserva de $userName para $destName?\n\n'
          'Esta acción notificará al usuario y liberará el cupo.';
      color = AppColors.error;
    } else {
      title = 'Cambiar estado';
      message = '¿Actualizar el estado de esta reserva?';
      color = AppColors.accent;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isConfirm ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: color),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message,
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isConfirm ? 'Confirmar' : isCancel ? 'Cancelar' : 'Actualizar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _admin.updateReservationStatus(r['id'], newStatus);
      _load();
      _showSnack(
        isConfirm
            ? '✅ Reserva confirmada para $destName'
            : isCancel
                ? '❌ Reserva cancelada'
                : '📝 Estado actualizado',
        true,
      );
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}', false);
    }
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Pendiente';
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '—';
    final date = DateTime.tryParse(d);
    if (date == null) return d;
    const m = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${m[date.month - 1]} ${date.year}';
  }

  int get _totalReservas => _reservations.length;
  int get _confirmadas =>
      _reservations.where((r) => r['status'] == 'confirmed').length;
  int get _pendientes =>
      _reservations.where((r) => r['status'] == 'pending').length;
  int get _canceladas =>
      _reservations.where((r) => r['status'] == 'cancelled').length;

  Widget _buildBody() {
    return Column(
      children: [
        // Barra de herramientas premium
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Búsqueda
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        onChanged: (v) {
                          _searchQuery = v;
                          _applyFilters();
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar por destino, usuario o email...',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3), fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.white.withOpacity(0.4), size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: Colors.white.withOpacity(0.4),
                                      size: 16),
                                  onPressed: () {
                                    _searchQuery = '';
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contador
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filtered.length} / ${_reservations.length}',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filtros de estado
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todas',
                      count: _totalReservas,
                      selected: _statusFilter == 'all',
                      color: AppColors.accent,
                      onTap: () {
                        setState(() => _statusFilter = 'all');
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pendientes',
                      count: _pendientes,
                      selected: _statusFilter == 'pending',
                      color: AppColors.warning,
                      onTap: () {
                        setState(() => _statusFilter = 'pending');
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Confirmadas',
                      count: _confirmadas,
                      selected: _statusFilter == 'confirmed',
                      color: AppColors.success,
                      onTap: () {
                        setState(() => _statusFilter = 'confirmed');
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Canceladas',
                      count: _canceladas,
                      selected: _statusFilter == 'cancelled',
                      color: AppColors.error,
                      onTap: () {
                        setState(() => _statusFilter = 'cancelled');
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 48, color: Colors.white.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text('No hay reservas que coincidan',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          return constraints.maxWidth > 700
                              ? FadeTransition(
                                  opacity: _animationController,
                                  child: _buildTable(),
                                )
                              : _buildCards();
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _th('Destino', flex: 3),
                _th('Usuario', flex: 3),
                _th('Fechas', flex: 3),
                _th('Viajeros', flex: 1),
                _th('Estado', flex: 2),
                const SizedBox(width: 100),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ..._filtered.map((r) => _ReservationRow(
                reservation: r,
                formatDate: _formatDate,
                statusLabel: _statusLabel,
                statusColor: _statusColor,
                onConfirm: r['status'] != 'confirmed'
                    ? () => _changeStatus(r, 'confirmed')
                    : null,
                onCancel: r['status'] != 'cancelled'
                    ? () => _changeStatus(r, 'cancelled')
                    : null,
              )),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _buildCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final r = _filtered[i];
        final dest = r['destinations'] as Map?;
        final profile = r['profiles'] as Map?;
        final status = r['status'] ?? 'pending';
        final color = _statusColor(status);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111D2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dest?['name'] ?? 'Destino',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: profile?['full_name'] ?? profile?['email'] ?? 'Usuario'),
              const SizedBox(height: 4),
              _InfoRow(
                  icon: Icons.calendar_month_outlined,
                  text:
                      '${_formatDate(r['start_date'])} → ${_formatDate(r['end_date'])}'),
              const SizedBox(height: 4),
              _InfoRow(
                  icon: Icons.people_outline_rounded,
                  text:
                      '${r['travelers'] ?? 1} viajero${(r['travelers'] ?? 1) > 1 ? 's' : ''}'),
              if (status != 'cancelled') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (status != 'confirmed')
                      Expanded(
                        child: _ActionButton(
                          label: 'Confirmar',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                          onTap: () => _changeStatus(r, 'confirmed'),
                        ),
                      ),
                    if (status != 'confirmed') const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: 'Cancelar',
                        icon: Icons.cancel_outlined,
                        color: AppColors.error,
                        onTap: () => _changeStatus(r, 'cancelled'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();
    return Scaffold(
      backgroundColor: const Color(0xFF070E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1520),
        title: const Text('Reservas', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? color.withOpacity(0.4) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? color : Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accent.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 13)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationRow extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final String Function(String?) formatDate;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _ReservationRow({
    required this.reservation,
    required this.formatDate,
    required this.statusLabel,
    required this.statusColor,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<_ReservationRow> createState() => _ReservationRowState();
}

class _ReservationRowState extends State<_ReservationRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final dest = r['destinations'] as Map?;
    final profile = r['profiles'] as Map?;
    final status = r['status'] ?? 'pending';
    final color = widget.statusColor(status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFF111D2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(dest?['name'] ?? '—',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 3,
              child: Text(
                profile?['full_name'] ?? profile?['email'] ?? '—',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${widget.formatDate(r['start_date'])} → ${widget.formatDate(r['end_date'])}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${r['travelers'] ?? 1}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.statusLabel(status),
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onConfirm != null)
                    Tooltip(
                      message: 'Confirmar',
                      child: Material(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: widget.onConfirm,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.check_rounded,
                                color: AppColors.success, size: 16),
                          ),
                        ),
                      ),
                    ),
                  if (widget.onConfirm != null) const SizedBox(width: 4),
                  if (widget.onCancel != null)
                    Tooltip(
                      message: 'Cancelar',
                      child: Material(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: widget.onCancel,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.close_rounded,
                                color: AppColors.error, size: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}