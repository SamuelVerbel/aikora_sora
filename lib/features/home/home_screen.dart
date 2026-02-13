import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcomeSection(),
                    const SizedBox(height: 30),
                    _searchBar(),
                    const SizedBox(height: 30),
                    _sectionTitle("Recomendado para ti"),
                    const SizedBox(height: 16),
                    _horizontalDestinations(),
                    const SizedBox(height: 30),
                    _sectionTitle("Explora por categoría"),
                    const SizedBox(height: 16),
                    _categories(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _welcomeSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.accent.withOpacity(0.2),
          backgroundImage:
              userAvatar != null ? NetworkImage(userAvatar!) : null,
          child: userAvatar == null
              ? Text(
                  userName.isNotEmpty ? userName[0] : 'V',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Hola, $userName 👋\n¿A dónde viajamos hoy?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            //Navigator.pushNamed(context, AppRoutes.notifications);
          },
        )
      ],
    );
  }

  Widget _searchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.explore);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.search),
            SizedBox(width: 10),
            Text("Buscar destinos, países..."),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
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
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                country,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
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