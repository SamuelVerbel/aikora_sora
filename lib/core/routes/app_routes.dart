import 'package:flutter/material.dart';

// Auth
import '../../features/auth/welcome/welcome_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/auth_gate.dart';

// Navigation
import '../../features/navigation/main_navigation_screen.dart';
import '../../features/reservations/reservations_screen.dart';
import '../../features/notifications/notifications_screen.dart';

// Home & profile
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';

// Trip & Explore
import '../../features/trip/plan_trip_screen.dart';
import '../../features/trip/plan_result_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/explore/screens/destination_detail_screen.dart';
import '../../features/explore/models/destination_model.dart';


class AppRoutes {
  static const String authGate = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';

  static const String main = '/main';

  static const String home = '/home';
  static const String profile = '/profile';
  static const String planTrip = '/plan';
  static const String explore = '/explore';
  static const String destinationDetail = '/destination-detail';
  static const String planResult = '/plan-result';
  static const String reservations = '/reservations';
  static const String notifications = '/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

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

      case main:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
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
        final dest = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => PlanTripScreen(
            preselectedDestination: dest is Destination ? dest : null,
          ),
        );

      case explore:
        return MaterialPageRoute(
          builder: (_) => const ExploreScreen(),
        );

      case destinationDetail:
        final destination = settings.arguments as Destination;
        return MaterialPageRoute(
          builder: (_) => DestinationDetailScreen(
            destination: destination,
          ),
        );

      case planResult:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PlanResultScreen(args: args),
        );

      case reservations:
        return MaterialPageRoute(
          builder: (_) => const ReservationsScreen(),
        );

      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
        );
    }
  }
}