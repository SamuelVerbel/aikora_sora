import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/routes/app_routes.dart';
import 'welcome/welcome_screen.dart';
import 'services/profile_service.dart';

/// AuthGate decide a dónde enviar al usuario:
/// - Si NO hay sesión: muestra Welcome.
/// - Si hay sesión: sincroniza perfil y navega a Main.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSub;

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
      debugPrint('Error inicializando auth: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _handleUserSession(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        _redirectToWelcome();
      }
    });
  }

  Future<void> _handleUserSession(User user) async {
    try {
      debugPrint('👤 Usuario autenticado: ${user.email}');
      await ProfileService().syncProfileAfterLogin(user);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
    } catch (e) {
      debugPrint('Error manejando sesión: $e');
      if (mounted) _showErrorSnackBar('Error al procesar el perfil');
    }
  }

  void _redirectToWelcome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
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
    if (user == null) return const WelcomeScreen();

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}