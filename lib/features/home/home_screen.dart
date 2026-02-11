import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '/features/profile/services/profile_service.dart';

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

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aikōra Sora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _welcomeSection(),
                  const SizedBox(height: 30),
                  _mainActions(),
                ],
              ),
            ),
    );
  }

  Widget _welcomeSection() {
    return Row(
      children: [
        // Avatar con fallback si no hay imagen
        CircleAvatar(
          radius: 30,
          backgroundImage: userAvatar != null ? NetworkImage(userAvatar!) : null,
          backgroundColor: AppColors.accent.withOpacity(0.2),
          child: userAvatar == null
              ? Text(
                  userName.isNotEmpty ? userName[0] : 'V',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $userName 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '¿A dónde quieres viajar hoy?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mainActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.auto_awesome,
          title: 'Planear viaje con IA',
          subtitle: 'Recomendaciones personalizadas',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.planTrip);
          },
        ),
        const SizedBox(height: 16),
        _actionCard(
          icon: Icons.explore,
          title: 'Explorar destinos',
          subtitle: 'Descubre lugares increíbles',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.explore);
          },
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: AppColors.accent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
