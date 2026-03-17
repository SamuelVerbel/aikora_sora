import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../trip/plan_trip_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    PlanTripScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 👈 Añadir esto

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        // ✅ Usa el color de superficie del tema
        backgroundColor: theme.colorScheme.surface, 
        selectedItemColor: AppColors.accent,
        unselectedItemColor: theme.brightness == Brightness.dark 
            ? Colors.grey[500] 
            : Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 10, // Un poco de sombra para separar del body
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: "Explorar"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: "Plan"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}