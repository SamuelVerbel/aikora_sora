// ignore_for_file: avoid_print

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

  // Estado de carga inicial (verificando si existe sesión previa)
  bool _isLoading = true;

  // Importante: guardamos la suscripción para cancelarla en dispose()
  StreamSubscription<AuthState>? _authSub; //

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  /// Se ejecuta 1 sola vez al abrir la app.
  /// Aquí verificamos si ya existía una sesión guardada (usuario logueado).
  Future<void> _initializeAuth() async {
    try {
      // currentSession devuelve sesión actual si existe (token guardado)
      final session = _supabase.auth.currentSession;

      // Si hay sesión, manejamos ese usuario inmediatamente
      if (session != null) {
        await _handleUserSession(session.user);
      }
    } catch (e) {
      print('Error inicializando auth: $e');
    } finally {
      // Terminamos la pantalla de “verificando sesión”
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // Listener global: reacciona a login / logout
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          _handleUserSession(session.user);
        } else if (event == AuthChangeEvent.signedOut) {
          _redirectToWelcome();
        }
      });
    }

  /// Cuando hay un usuario autenticado:
  /// 1) Sincronizamos el perfil (nombre/avatar) en la tabla profiles.
  /// 2) Navegamos a la pantalla principal (MainNavigationScreen).
  Future<void> _handleUserSession(User user) async {
    try {
      print('👤 Usuario autenticado: ${user.email}');

      // El trigger ya crea el perfil; aquí solo mejoramos datos con metadata (Google)
      await ProfileService().syncProfileAfterLogin(user);

      // Navegación a la pantalla principal
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
    } catch (e) {
      print('Error manejando sesión: $e');
      if (mounted) {
        _showErrorSnackBar('Error al procesar el perfil');
      }
    }
  }

  /// Si el usuario sale o no hay sesión, volvemos a Welcome.
  void _redirectToWelcome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    }
  }

  /// SnackBar de error genérico para problemas del gate.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    // Evita fugas de memoria: cancelamos el listener de auth
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI de carga mientras verificamos sesión al arranque
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

    // Si no hay usuario, mostramos el Welcome directamente
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    // Si sí hay usuario, normalmente ya se navega a Main.
    // Esto es un “fallback visual” por si la navegación tarda unos ms.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
