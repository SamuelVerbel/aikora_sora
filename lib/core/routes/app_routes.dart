// lib/core/routes/app_routes.dart

import 'package:aikora_sora/features/admin/admin_dashboard_screen.dart';
import 'package:aikora_sora/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';

// ── AUTH ─────────────────────────────────────────────────────────────────────
import '../../features/auth/welcome/welcome_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart'; // NUEVO IMPORT
import '../../features/auth/auth_gate.dart';

// ── NAVIGATION + FEATURES ────────────────────────────────────────────────────
import '../../features/navigation/main_navigation_screen.dart';
import '../../features/reservations/reservations_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/restaurants/restaurants_screen.dart';

// ── HOME & PROFILE ──────────────────────────────────────────────────────────
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';

// ── TRIP & EXPLORE ──────────────────────────────────────────────────────────
import '../../features/trip/plan_trip_screen.dart';
import '../../features/trip/plan_result_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/explore/screens/destination_detail_screen.dart';
import '../../features/explore/models/destination_model.dart';

// ── AI ───────────────────────────────────────────────────────────────────────
import '../../features/ai/chat_screen.dart';

class AppRoutes {
  // Auth
  static const String authGate = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Navegación principal
  static const String main = '/main';

  // Pantallas
  static const String home = '/home';
  static const String profile = '/profile';
  static const String planTrip = '/plan';
  static const String explore = '/explore';
  static const String destinationDetail = '/destination-detail';
  static const String planResult = '/plan-result';
  static const String reservations = '/reservations';
  static const String notifications = '/notifications';
  static const String restaurants = '/restaurants';
  static const String splash = '/splash';
  static const String admin = '/admin';

  // RF-21 — Chat con Sora
  static const String chat = '/chat';

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Error de navegación')),
      ),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case authGate:
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPassword: // NUEVO CASE
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case main:
        return MaterialPageRoute(
            builder: (_) => const MainNavigationScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case planTrip:
        final dest = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => PlanTripScreen(
            preselectedDestination: dest is Destination ? dest : null,
          ),
        );

      case explore:
        return MaterialPageRoute(builder: (_) => const ExploreScreen());

      case destinationDetail:
        final args = settings.arguments;
        if (args is! Destination) return _errorRoute();
        return MaterialPageRoute(
          builder: (_) => DestinationDetailScreen(destination: args),
        );

      case planResult:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
            builder: (_) => PlanResultScreen(args: args));

      case reservations:
        return MaterialPageRoute(
            builder: (_) => const ReservationsScreen());

      case notifications:
        return MaterialPageRoute(
            builder: (_) => const NotificationsScreen());

      case restaurants:
        return MaterialPageRoute(
          builder: (_) => const RestaurantsScreen(),
          settings: settings,
        );

      case chat:
        final dest = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            destination: dest is Destination ? dest : null,
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const AuthGate());
    }
  }
}