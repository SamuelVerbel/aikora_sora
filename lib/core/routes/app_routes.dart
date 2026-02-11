import 'package:flutter/material.dart';

// Auth
import '../../features/auth/welcome/welcome_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '/features/auth/auth_gate.dart';

// Home & profile
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';

// Trip / IA
import 'package:aikora_sora/screens/plan_trip_screen.dart';
import '../../features/explore/explore_screen.dart';


class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String planTrip = '/plan';
  static const String explore = '/explore';


  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case planTrip:
        return MaterialPageRoute(
          builder: (_) => const PlanTripScreen(),
        );

      case explore:
        return MaterialPageRoute(builder: (_) => const ExploreScreen());

      default:
      return MaterialPageRoute(
        builder: (_) => const AuthGate(),
      );
    }
  }
}
