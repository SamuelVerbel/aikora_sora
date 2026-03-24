import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'admin_service.dart';
import 'destinations_admin_screen.dart';
import 'users_admin_screen.dart';
import 'reservations_admin_screen.dart';

/// Panel de administración principal de Aikōra Sora.
/// Layout premium con gráficos y métricas avanzadas.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _admin = AdminService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isAdmin = false;
  int _selectedIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkAccessAndLoad();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAccessAndLoad() async {
    final isAdmin = await _admin.isAdmin();
    if (!isAdmin) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso restringido — Se requiere rol de administrador'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final stats = await _admin.getDashboardStats();
    if (mounted) {
      setState(() {
        _isAdmin = true;
        _stats = stats;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 1:
        return const DestinationsAdminScreen(embedded: true);
      case 2:
        return const UsersAdminScreen(embedded: true);
      case 3:
        return const ReservationsAdminScreen(embedded: true);
      default:
        return _DashboardHome(
          stats: _stats,
          onNavigate: (i) => setState(() => _selectedIndex = i),
          onRefresh: _checkAccessAndLoad,
          animationController: _animationController,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1520),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 16),
              Text('Verificando acceso...', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) return const SizedBox.shrink();

    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFF070E17),
        body: Row(
          children: [
            _AdminSidebar(
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: _sectionTitle(_selectedIndex),
                    onRefresh: _checkAccessAndLoad,
                  ),
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: const Color(0xFF070E17),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B1520),
          title: Text(
            _sectionTitle(_selectedIndex),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
              onPressed: _checkAccessAndLoad,
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF0B1520),
          child: _AdminSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (i) {
              setState(() => _selectedIndex = i);
              Navigator.pop(context);
            },
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildContent(),
      );
    }
  }

  String _sectionTitle(int index) {
    switch (index) {
      case 1:
        return 'Destinos Turísticos';
      case 2:
        return 'Gestión de Usuarios';
      case 3:
        return 'Reservas';
      default:
        return 'Dashboard';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR (sin cambios)
// ─────────────────────────────────────────────────────────────────────────────

class _AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;

  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1520),
        border: Border(
          right: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logo/app_icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.flight_takeoff_rounded,
                                color: Colors.white, size: 18),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Aikōra Sora',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'ADMIN PANEL',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  selected: selectedIndex == 0,
                  onTap: () => onSelect(0),
                ),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.place_rounded,
                  label: 'Destinos',
                  selected: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.people_rounded,
                  label: 'Usuarios',
                  selected: selectedIndex == 2,
                  onTap: () => onSelect(2),
                ),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.book_online_rounded,
                  label: 'Reservas',
                  selected: selectedIndex == 3,
                  onTap: () => onSelect(3),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _SidebarItem(
              icon: Icons.arrow_back_rounded,
              label: 'Volver a la app',
              selected: false,
              onTap: onBack,
              accent: false,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              'v1.0 · Acceso restringido',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool accent;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: AppColors.accent.withOpacity(0.25))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected
                    ? AppColors.accent
                    : Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              if (selected) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const _TopBar({required this.title, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1520),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Actualizar datos',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD HOME CON GRÁFICOS Y MÉTRICAS PRO
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHome extends StatelessWidget {
  final Map<String, dynamic> stats;
  final ValueChanged<int> onNavigate;
  final VoidCallback onRefresh;
  final AnimationController animationController;

  const _DashboardHome({
    required this.stats,
    required this.onNavigate,
    required this.onRefresh,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
    
    final totalDestinos = stats['total_destinations'] ?? 0;
    final totalUsuarios = stats['total_users'] ?? 0;
    final totalReservas = stats['total_reservations'] ?? 0;
    final pendientes = stats['pending_reservations'] ?? 0;
    
    // Calcular porcentaje de ocupación
    final porcentajeOcupacion = totalDestinos > 0 
        ? (pendientes / totalDestinos).clamp(0.0, 1.0) 
        : 0.0;
    
    // Datos para gráfico de anillo
    final chartData = [
      PieChartSectionData(
        value: totalReservas - pendientes,
        title: 'Confirmadas',
        color: AppColors.success,
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      PieChartSectionData(
        value: pendientes,
        title: 'Pendientes',
        color: AppColors.warning,
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    ];

    return FadeTransition(
      opacity: animationController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con animación
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animationController,
                curve: Curves.easeOut,
              )),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenido de vuelta 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.white.withOpacity(0.4)),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge de estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Stats grid premium
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(CurvedAnimation(
                parent: animationController,
                curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
              )),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _PremiumStatCard(
                    icon: Icons.place_rounded,
                    label: 'Destinos',
                    value: '$totalDestinos',
                    color: AppColors.accent,
                    onTap: () => onNavigate(1),
                    trend: '+12%',
                    trendUp: true,
                  ),
                  _PremiumStatCard(
                    icon: Icons.people_rounded,
                    label: 'Usuarios',
                    value: '$totalUsuarios',
                    color: Colors.blue.shade400,
                    onTap: () => onNavigate(2),
                    trend: '+8%',
                    trendUp: true,
                  ),
                  _PremiumStatCard(
                    icon: Icons.book_online_rounded,
                    label: 'Reservas',
                    value: '$totalReservas',
                    color: AppColors.success,
                    onTap: () => onNavigate(3),
                    trend: pendientes > 0 ? '+${pendientes}' : '0',
                    trendUp: pendientes > 0,
                  ),
                  _PremiumStatCard(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pendientes',
                    value: '$pendientes',
                    color: AppColors.warning,
                    onTap: () => onNavigate(3),
                    trend: pendientes > 0 ? 'Urgente' : 'Completado',
                    trendUp: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Sección de gráficos
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gráfico de anillo - Estado de reservas
                Expanded(
                  flex: 2,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(CurvedAnimation(
                      parent: animationController,
                      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                    )),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pie_chart, color: AppColors.accent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Estado de Reservas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sections: chartData,
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                startDegreeOffset: -90,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LegendDot(color: AppColors.success, label: 'Confirmadas'),
                              const SizedBox(width: 16),
                              _LegendDot(color: AppColors.warning, label: 'Pendientes'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Métricas rápidas
                Expanded(
                  flex: 3,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(CurvedAnimation(
                      parent: animationController,
                      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
                    )),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.speed, color: AppColors.accent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Métricas de Desempeño',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _MetricRow(
                            label: 'Tasa de conversión',
                            value: totalReservas > 0 
                                ? '${((totalReservas - pendientes) / totalReservas * 100).toStringAsFixed(1)}%'
                                : '0%',
                            icon: Icons.trending_up,
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 12),
                          _MetricRow(
                            label: 'Usuarios activos',
                            value: '${(totalUsuarios * 0.75).toInt()}',
                            icon: Icons.people,
                            color: Colors.blue.shade400,
                            subtitle: 'aprox. 75% del total',
                          ),
                          const SizedBox(height: 12),
                          _MetricRow(
                            label: 'Destinos por usuario',
                            value: totalUsuarios > 0 
                                ? '${(totalDestinos / totalUsuarios).toStringAsFixed(1)}'
                                : '0',
                            icon: Icons.place,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de accesos rápidos con animación
            ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1).animate(CurvedAnimation(
                parent: animationController,
                curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
              )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCESO RÁPIDO',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      final cards = [
                        _QuickCardPro(
                          icon: Icons.add_location_alt_rounded,
                          title: 'Nuevo destino',
                          subtitle: 'Agregar al catálogo',
                          color: AppColors.accent,
                          onTap: () => onNavigate(1),
                        ),
                        _QuickCardPro(
                          icon: Icons.manage_accounts_rounded,
                          title: 'Gestionar usuarios',
                          subtitle: 'Roles y permisos',
                          color: Colors.blue.shade400,
                          onTap: () => onNavigate(2),
                        ),
                        _QuickCardPro(
                          icon: Icons.assignment_turned_in_rounded,
                          title: 'Revisar reservas',
                          subtitle: 'Aprobar pendientes',
                          color: AppColors.success,
                          onTap: () => onNavigate(3),
                          badge: pendientes > 0 ? '${pendientes}' : null,
                        ),
                      ];

                      if (isWide) {
                        return Row(
                          children: cards
                              .map((c) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: c,
                                    ),
                                  ))
                              .toList(),
                        );
                      }
                      return Column(
                        children: cards
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: c,
                                ))
                            .toList(),
                      );
                    },
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

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTES PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final String trend;
  final bool trendUp;

  const _PremiumStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF111D2E),
                  const Color(0xFF0A0F1A),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trendUp 
                            ? AppColors.success.withOpacity(0.12) 
                            : AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trendUp ? Icons.trending_up : Icons.trending_down,
                            size: 10,
                            color: trendUp ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            trend,
                            style: TextStyle(
                              fontSize: 9,
                              color: trendUp ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: double.parse(value)),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, val, child) {
                    return Text(
                      val.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuickCardPro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _QuickCardPro({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF111D2E),
                const Color(0xFF0A0F1A),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.25), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}