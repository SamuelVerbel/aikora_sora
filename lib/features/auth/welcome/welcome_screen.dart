import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';

/// Primera pantalla que ve el usuario si NO tiene sesión activa.
/// Su único propósito: presentar la marca y llevar al login o al registro.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

/// SingleTickerProviderStateMixin: solo necesitamos 1 controlador aquí
class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim; // todo el contenido aparece con fade
  late Animation<Offset> _slideAnim; // el contenido sube desde abajo

  @override
  void initState() {
    super.initState();

    // Animación de 1.2 segundos que arranca al abrir la pantalla
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade de 0 a 1 con curva suave
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    // Slide desde 30% debajo hasta posición original
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    // Ejecuta la animación al mostrar la pantalla
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // siempre liberar para evitar memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fondo degradado oscuro, igual que el Splash para mantener coherencia visual
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1C2D), // Azul marino profundo
              Color(0xFF0F2744),
              Color(0xFF091520),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2), //espacio superior proporcional

                // ── Logo + Título + Subtítulo ───────────────────────────
                // Todo entra con fade y slide simultáneos para un efecto más dinámico
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // Logo circular con sombra sutil para destacar
                        Image.asset(
                          'assets/logo/app_icon.png',
                          height: 120,
                          width: 120,
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Aikōra Sora',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Planifica viajes inteligentes\ncon ayuda de IA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white60,
                            height: 1.6, //interlineado para mejor legibilidad en multilinea
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3), //empuja los botones hacia abajo proporcionalmente

                // ── Botones de acción ───────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      // Botón primario → va a RegisterScreen
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.accent, // verde-azulado
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Crear cuenta',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Botón secundario (outlined) → va a LoginScreen
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.login),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white24, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Tagline inferior decorativo
                      const Text(
                        'Tu próxima aventura comienza aquí ✈️',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
