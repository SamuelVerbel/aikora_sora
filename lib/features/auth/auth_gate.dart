// lib/features/auth/auth_gate.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'welcome/welcome_screen.dart';
import 'services/profile_service.dart';

/// AuthGate decide a dónde enviar al usuario con animaciones premium
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSub;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
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
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0F1A),
                const Color(0xFF0F1A2A),
                const Color(0xFF0B1525),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flight_takeoff_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Aikōra Sora',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Verificando sesión...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return const WelcomeScreen();

    // Si hay usuario pero aún no redirigió, mostrar loading
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Cargando tu perfil...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}