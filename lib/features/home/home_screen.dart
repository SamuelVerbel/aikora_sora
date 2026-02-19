import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../auth/services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = Supabase.instance.client.auth.currentUser;

  String userName = 'Viajero';
  String? userAvatar;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final profile = await ProfileService().getProfile(user!.id);

    if (mounted) {
      setState(() {
        userName = profile?['name'] ?? 'Viajero';
        userAvatar = profile?['avatar'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcomeSection(),
                    const SizedBox(height: 32),
                    _searchBar(),
                    const SizedBox(height: 40),
                    _sectionHeader("Recomendado para ti"),
                    const SizedBox(height: 20),
                    _horizontalDestinations(),
                    const SizedBox(height: 40),
                    _sectionHeader("Explora por categoría"),
                    const SizedBox(height: 20),
                    _categories(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _welcomeSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          backgroundImage:
              userAvatar != null ? NetworkImage(userAvatar!) : null,
          child: userAvatar == null
              ? Text(
                  userName.isNotEmpty ? userName[0] : 'V',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola, $userName 👋",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                "Descubre tu próxima aventura",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _searchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.explore);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search),
            SizedBox(width: 12),
            Text(
              "Buscar destinos, países...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _horizontalDestinations() {
    return SizedBox(
      height: 190,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _destinationCard(
            "Cartagena",
            "Colombia",
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
          ),
          _destinationCard(
            "Kyoto",
            "Japón",
            "https://images.unsplash.com/photo-1493558103817-58b2924bce98",
          ),
          _destinationCard(
            "Santorini",
            "Grecia",
            "https://images.unsplash.com/photo-1469474968028-56623f02e42e",
          ),
        ],
      ),
    );
  }

  Widget _destinationCard(String title, String country, String image) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.network(
              image,
              height: 200,
              width: 180,
              fit: BoxFit.cover,
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    country,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _categories() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: const [
        Chip(label: Text("Playa")),
        Chip(label: Text("Cultura")),
        Chip(label: Text("Aventura")),
        Chip(label: Text("Gastronomía")),
        Chip(label: Text("Montaña")),
      ],
    );
  }
}