import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'admin_service.dart';
import 'destinations_admin_screen.dart';
import 'users_admin_screen.dart';
import 'reservations_admin_screen.dart';

/// Panel de administración principal de Aikōra Sora.
/// Solo accesible para usuarios con role = 'admin'.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _admin = AdminService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    final isAdmin = await _admin.isAdmin();
    if (!isAdmin) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso restringido — Se requiere rol de administrador'),
            backgroundColor: Colors.red,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 22),
            SizedBox(width: 10),
            Text('Panel de Administración',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF0B1520) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _checkAccessAndLoad,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkAccessAndLoad,
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Saludo ───────────────────────────────────────────────────
              Text(
                'Bienvenido, Admin 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0B1C2D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gestiona todos los recursos de Aikōra Sora desde aquí.',
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Stats Cards ───────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    icon: Icons.place_outlined,
                    label: 'Destinos',
                    value: '${_stats['total_destinations'] ?? 0}',
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.people_outline,
                    label: 'Usuarios',
                    value: '${_stats['total_users'] ?? 0}',
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.book_online_outlined,
                    label: 'Reservas',
                    value: '${_stats['total_reservations'] ?? 0}',
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.pending_actions_outlined,
                    label: 'Pendientes',
                    value: '${_stats['pending_reservations'] ?? 0}',
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Módulos de gestión ────────────────────────────────────────
              Text(
                'Gestión',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0B1C2D),
                ),
              ),
              const SizedBox(height: 14),

              _AdminModuleCard(
                icon: Icons.place_rounded,
                title: 'Destinos turísticos',
                subtitle: 'Crear, editar, eliminar y gestionar imágenes',
                color: AppColors.accent,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DestinationsAdminScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _AdminModuleCard(
                icon: Icons.people_rounded,
                title: 'Usuarios',
                subtitle: 'Ver perfiles, asignar roles y gestionar cuentas',
                color: Colors.blue,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UsersAdminScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _AdminModuleCard(
                icon: Icons.book_online_rounded,
                title: 'Reservas',
                subtitle: 'Revisar y actualizar el estado de reservas',
                color: Colors.green,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReservationsAdminScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Footer ────────────────────────────────────────────────────
              Center(
                child: Text(
                  'Aikōra Sora Admin · Acceso restringido',
                  style: TextStyle(
                      color: Colors.grey[400], fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Componentes
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152030) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0B1C2D),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF152030) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF0B1C2D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}