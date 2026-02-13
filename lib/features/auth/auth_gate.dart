import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/routes/app_routes.dart';
import 'welcome/welcome_screen.dart';
import 'services/profile_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session != null) {
        await _handleUserSession(session.user);
      }
    } catch (e) {
      print('Error inicializando auth: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('🔑 Auth state changed: $event');

      if (event == AuthChangeEvent.signedIn && session != null) {
        _handleUserSession(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        _redirectToWelcome();
      }
    });
  }

  Future<void> _handleUserSession(User user) async {
    try {
      print('👤 Usuario autenticado: ${user.email}');

      await ProfileService().createOrUpdateProfile(user);

      if (mounted) {
        Navigator.of(context)
            .pushReplacementNamed(AppRoutes.main);
      }
    } catch (e) {
      print('Error manejando sesión: $e');
      if (mounted) {
        _showErrorSnackBar('Error al procesar el perfil');
      }
    }
  }

  void _redirectToWelcome() {
    if (mounted) {
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.welcome);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Verificando sesión...'),
            ],
          ),
        ),
      );
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    // Mientras navega a Main
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}