import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../auth/services/profile_service.dart';
import '../explore/models/destination_model.dart';

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
    {'label': 'Playa',       'icon': Icons.beach_access_outlined,  'tag': 'playa'},
    {'label': 'Cultura',     'icon': Icons.museum_outlined,         'tag': 'cultura'},
    {'label': 'Aventura',    'icon': Icons.hiking_outlined,         'tag': 'aventura'},
    {'label': 'Gastronomía', 'icon': Icons.restaurant_outlined,     'tag': 'gastronomia'},
    {'label': 'Montaña',     'icon': Icons.landscape_outlined,      'tag': 'montana'},
    {'label': 'Ciudad',      'icon': Icons.location_city_outlined,  'tag': 'ciudad'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = _supabase.auth.currentUser;

    await Future.wait([
      _loadProfile(user),
      _loadFeatured(),
    ]);
  }

  Future<void> _loadProfile(User? user) async {
    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    final profile = await ProfileService().getProfile(user.id);
    if (mounted) {
      setState(() {
        userName   = profile?['full_name'] ?? 'Viajero';
        userAvatar = profile?['avatar_url'];
        isLoading  = false;
      });
    }
  }

  Future<void> _loadFeatured() async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .order('rating', ascending: false)
          .limit(6);

      final list = (response as List)
          .map((e) => Destination.fromJson(e))
          .toList();

      if (mounted) {
        setState(() {
        _featured = list;
        _loadingDestinations = false;
      });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDestinations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.accent,
              child: CustomScrollView(
                slivers: [
                  // ── AppBar con saludo ───────────────────────
                  SliverToBoxAdapter(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _welcomeSection(),
                            const SizedBox(height: 24),
                            _searchBar(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Destinos recomendados ───────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recomendado para ti',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRoutes.explore),
                            child: const Text('Ver todos',
                                style: TextStyle(color: AppColors.accent)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: _loadingDestinations
                          ? const Center(child: CircularProgressIndicator())
                          : _featured.isEmpty
                              ? _emptyDestinations()
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(
                                      left: 24, right: 8),
                                  itemCount: _featured.length,
                                  itemBuilder: (_, i) =>
                                      _DestinationCard(
                                        destination: _featured[i],
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.destinationDetail,
                                          arguments: _featured[i],
                                        ),
                                      ),
                                ),
                    ),
                  ),

                  // ── Categorías ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
                      child: const Text('Explora por categoría',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _CategoryCard(
                          label: _categories[i]['label'],
                          icon:  _categories[i]['icon'],
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.explore,
                            arguments: {'category': _categories[i]['tag']},
                          ),
                        ),
                        childCount: _categories.length,
                      ),
                    ),
                  ),

                  // ── Acceso rápido ───────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
                      child: const Text('Acceso rápido',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.auto_awesome,
                              label: 'Planear viaje',
                              color: AppColors.accent,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.planTrip),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.luggage_outlined,
                              label: 'Mis reservas',
                              color: AppColors.primary,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.reservations),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Sección de bienvenida ─────────────────────────────────────────────────

  Widget _welcomeSection() {
    final firstName = userName.split(' ').first;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.accent.withOpacity(0.15),
            backgroundImage:
                userAvatar != null ? NetworkImage(userAvatar!) : null,
            child: userAvatar == null
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'V',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, $firstName 👋',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              Text('Descubre tu próxima aventura',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 13)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notifications),
        ),
      ],
    );
  }

  // ── Barra de búsqueda ─────────────────────────────────────────────────────

  Widget _searchBar() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.explore),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.accent),
            const SizedBox(width: 12),
            Text('Buscar destinos, países...',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _emptyDestinations() {
    return Center(
      child: Text('Sin destinos aún. Agrega datos en Supabase.',
          style: TextStyle(color: Colors.grey[400])),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _DestinationCard extends StatelessWidget {
  final Destination destination;
  final VoidCallback onTap;

  const _DestinationCard({required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Imagen
              Image.network(
                destination.mainImage,
                height: 220,
                width: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              ),
              // Gradiente
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        (destination.rating ?? 4.5).toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              // Texto
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(destination.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 12),
                      const SizedBox(width: 3),
                      Text(destination.country,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
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

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
