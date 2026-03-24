import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../auth/services/profile_service.dart';
import '../explore/models/destination_model.dart';
import '../explore/data/destinations_repository.dart';
import '../../core/widgets/section_title.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final _repository = DestinationsRepository();

  String userName = 'Viajero';
  String? userAvatar;
  bool isLoading = true;
  List<Destination> _featured = [];

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Playa',       'icon': Icons.beach_access_outlined,  'tag': 'playa'},
    {'label': 'Cultura',     'icon': Icons.museum_outlined,         'tag': 'cultura'},
    {'label': 'Aventura',    'icon': Icons.terrain_outlined,        'tag': 'aventura'},
    {'label': 'Gastronomía', 'icon': Icons.restaurant_outlined,     'tag': 'gastronomia'},
    {'label': 'Montaña',     'icon': Icons.landscape_outlined,      'tag': 'montaña'},
    {'label': 'Ciudad',      'icon': Icons.location_city_outlined,  'tag': 'ciudad'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadUserData(), _loadFeatured()]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Sincronizar perfil primero (escribe nombre/avatar de Google si faltan)
      await ProfileService().syncProfileAfterLogin(user);

      Map<String, dynamic>? profile = await ProfileService().getProfile(user.id);

      // Si full_name sigue vacío, usar metadata de Auth directamente
      String? name = profile?['full_name'];
      if (name == null || name.isEmpty || name == 'Usuario') {
        final meta = user.userMetadata ?? {};
        name = meta['name'] ?? meta['full_name'] ?? meta['email']?.split('@').first;
      }

      if (mounted) {
        setState(() {
          userName = name?.split(' ')[0] ?? 'Viajero';
          userAvatar = profile?['avatar_url']
              ?? user.userMetadata?['avatar_url']
              ?? user.userMetadata?['picture'];
        });
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      // Fallback a metadata de Auth sin BD
      final meta = _supabase.auth.currentUser?.userMetadata ?? {};
      if (mounted) {
        setState(() {
          userName = (meta['name'] ?? meta['full_name'] ?? 'Viajero')
              .toString().split(' ')[0];
          userAvatar = meta['avatar_url'] ?? meta['picture'];
        });
      }
    }
  }

  Future<void> _loadFeatured() async {
    try {
      final all = await _repository.getDestinations();
      if (mounted) {
        setState(() {
          _featured = (List<Destination>.from(all)
                ..sort((a, b) => b.rating.compareTo(a.rating)))
              .take(5)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando destacados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 700;
    final maxWidth = isWide ? 700.0 : double.infinity;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: CustomScrollView(
            slivers: [
              // ── HEADER ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, isWide ? 40 : 60, 24, 40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1C2D) : theme.primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Explora ahora',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Text('Hola, $userName 👋',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white24,
                          backgroundImage: userAvatar != null
                              ? NetworkImage(userAvatar!)
                              : null,
                          child: userAvatar == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── ACCESOS RÁPIDOS ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.auto_awesome,
                          label: 'Planear con IA',
                          color: AppColors.accent,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.planTrip),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.bookmark_outline,
                          label: 'Mis Reservas',
                          // FIX: color adaptable al tema — en claro usa accent
                          // para que sea legible sobre fondo casi blanco
                          color: isDark ? Colors.orange : AppColors.accent,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.reservations),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── CATEGORÍAS ─────────────────────────────────────────────
              // FIX: en web (isWide) usamos Wrap en lugar de ListView horizontal
              // para evitar overflow cuando el contenedor ya está constrainado a 700px
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: SectionTitle(title: 'Categorías'),
                    ),
                    isWide
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories
                                  .map((cat) => _CategoryItem(
                                        icon: cat['icon'],
                                        label: cat['label'],
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.explore,
                                          arguments: {'category': cat['tag']},
                                        ),
                                      ))
                                  .toList(),
                            ),
                          )
                        : SizedBox(
                            height: 100,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                return _CategoryItem(
                                  icon: cat['icon'],
                                  label: cat['label'],
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.explore,
                                    arguments: {'category': cat['tag']},
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),

              // ── DESTINOS DESTACADOS ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: SectionTitle(
                    title: 'Destinos Populares',
                    onActionTap: () =>
                        Navigator.pushNamed(context, AppRoutes.explore),
                    actionLabel: 'Ver todos',
                  ),
                ),
              ),

              if (_featured.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : Text('No hay destinos disponibles',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5))),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dest = _featured[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                            24, index == 0 ? 16 : 12, 24, 0),
                        child: _FeaturedCard(
                          destination: dest,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.destinationDetail,
                            arguments: dest,
                          ),
                        ),
                      );
                    },
                    childCount: _featured.length,
                  ),
                ),

              // Espaciado final para el bottom nav
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
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

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.2 : 0.06),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Icon(icon, color: AppColors.accent, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  // FIX: en modo claro el texto usa el mismo color del ícono
                  // para asegurar contraste sobre fondo casi blanco
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Destination destination;
  final VoidCallback onTap;

  const _FeaturedCard({required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Hero(
                tag: destination.id,
                child: CachedNetworkImage(
                  imageUrl: destination.mainImage,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 180,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported,
                        size: 40,
                        color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(destination.title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.location_on_outlined,
                              size: 13,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.45)),
                          const SizedBox(width: 3),
                          Text(
                            '${destination.city}, ${destination.country}',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                fontSize: 12),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text('${destination.rating}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        'Desde \$${destination.priceMin.toInt()}',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
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