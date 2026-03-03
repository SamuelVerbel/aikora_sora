import 'package:flutter/material.dart';

// ── AUTH ─────────────────────────────────────────────────────────────────────
// Pantallas de inicio de sesión/registro y “gate” inicial.
import '../../features/auth/welcome/welcome_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
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

/// AppRoutes sirve para:
/// 1) Tener los nombres de rutas en un solo lugar (evitar typos).
/// 2) Centralizar la creación de rutas (y manejar argumentos).
class AppRoutes {
  // Rutas base de auth
  static const String authGate = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';

  //Navegación principal (BottomNav / tabs)
  static const String main = '/main';

  // Rutas de pantallas
  static const String home = '/home';
  static const String profile = '/profile';
  static const String planTrip = '/plan';
  static const String explore = '/explore';
  static const String destinationDetail = '/destination-detail';
  static const String planResult = '/plan-result';
  static const String reservations = '/reservations';
  static const String notifications = '/notifications';
  static const String restaurants = '/restaurants';

  /// Genera la ruta según settings.name.
  /// Ventaja: puedes interceptar argumentos, validar tipos y evitar crashes.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      
      // ── AUTH GATE ──
      case authGate:
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
        );

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

      // ── MAIN NAV ──
      case main:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );

      // ── HOME ──
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      // ── PROFILE ──
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      // ── PLAN TRIP ──
      // Aquí recibimos opcionalmente un Destination (cuando vienes desde el detalle).
      case planTrip:
        final dest = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => PlanTripScreen(
            preselectedDestination: dest is Destination ? dest : null,
          ),
        );

      // ── EXPLORE ──
      case explore:
      // OJO: aquí podrías recibir filtros (ej: {'category': 'playa'}),
      // pero por ahora ExploreScreen se encarga de leerlos desde settings.arguments.
        return MaterialPageRoute(
          builder: (_) => const ExploreScreen(),
        );

      // ── DESTINATION DETAIL ──
      case destinationDetail:
      // Este sí es obligatorio: si no viene, el cast rompe.
        final destination = settings.arguments as Destination;
        return MaterialPageRoute(
          builder: (_) => DestinationDetailScreen(
            destination: destination,
          ),
        );

      // ── PLAN RESULT ──
      case planResult:
      // Args del plan: fechas, viajeros, presupuesto, etc.
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PlanResultScreen(args: args),
        );

      // ── RESERVATIONS ──
      case reservations:
        return MaterialPageRoute(
          builder: (_) => const ReservationsScreen(),
        );

      // ── NOTIFICATIONS ──
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );

      // ── RESTAURANTS ──
      case restaurants:
        return MaterialPageRoute(
          builder: (_) => const RestaurantsScreen(),
          settings: settings, // ← ESTO es lo que faltaba
        );

      // ── DEFAULT ──
      default:
      // Si llega una ruta desconocida, volvemos al AuthGate para no “romper” la app.
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
        );
    }
  }
}