import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../auth/services/profile_service.dart';
import '../explore/models/destination_model.dart';
import '../../core/widgets/section_title.dart'; // Asegúrate de tener este import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  String userName = 'Viajero';
  String? userAvatar;
  bool isLoading = true;
  List<Destination> _featured = [];
  bool _loadingDestinations = true;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Playa', 'icon': Icons.beach_access_outlined, 'tag': 'playa'},
    {'label': 'Cultura', 'icon': Icons.museum_outlined, 'tag': 'cultura'},
    {'label': 'Aventura', 'icon': Icons.terrain_outlined, 'tag': 'aventura'},
    {'label': 'Gastronomía', 'icon': Icons.restaurant_outlined, 'tag': 'gastronomia'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    // Aquí cargarías tus destinos reales de Supabase si los tienes listos
    setState(() => isLoading = false);
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final profile = await ProfileService().getProfile(user.id);
        
        if (mounted && profile != null) { // 👈 Añadimos la comprobación de profile != null
          setState(() {
            // Usamos ?. para acceder de forma segura
            userName = profile['full_name']?.split(' ')[0] ?? 'Viajero';
            userAvatar = profile['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── HEADER PREMIUM ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1C2D) : theme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explora ahora',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            'Hola, $userName 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white24,
                        backgroundImage: userAvatar != null ? NetworkImage(userAvatar!) : null,
                        child: userAvatar == null 
                            ? const Icon(Icons.person, color: Colors.white) 
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── ACCESOS RÁPIDOS (PLANEAR / RESERVAS) ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.auto_awesome,
                      label: 'Planear con IA',
                      color: AppColors.accent,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.planTrip),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.bookmark_outline,
                      label: 'Mis Reservas',
                      color: Colors.orange,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.reservations),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CATEGORÍAS ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SectionTitle(title: 'Categorías'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _CategoryItem(
                        icon: cat['icon'],
                        label: cat['label'],
                        onTap: () {
                          // Navegar a explorar con filtro
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── DESTINOS DESTACADOS ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                children: [
                  SectionTitle(
                    title: 'Destinos Populares',
                    onActionTap: () => Navigator.pushNamed(context, AppRoutes.explore),
                    actionLabel: 'Ver todos',
                  ),
                  const SizedBox(height: 16),
                  // Aquí iría tu lista de destinos, por ahora un placeholder elegante
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Center(
                      child: Text(
                        'Cargando destinos...',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── WIDGETS DE APOYO CORREGIDOS ─────────────────────────────────────────────

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Icon(icon, color: AppColors.accent, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}