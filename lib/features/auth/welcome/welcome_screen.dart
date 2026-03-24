// lib/features/auth/welcome/welcome_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeLogo;
  late Animation<double> _fadeText;
  late Animation<double> _fadeButtons;
  late Animation<Offset> _slideLogo;
  late Animation<Offset> _slideText;
  
  late List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(80, (index) => Star());
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    
    _fadeLogo = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _slideLogo = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    
    _fadeText = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    _slideText = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    
    _fadeButtons = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente animado
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A0F1A),
                      const Color(0xFF0F1A2A),
                      const Color(0xFF0B1525),
                      const Color(0xFF050A12),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: CustomPaint(
                  painter: StarFieldPainter(_stars, _controller.value),
                  size: Size.infinite,
                ),
              );
            },
          ),
          
          // Efecto de brillo sutil
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  AppColors.accent.withOpacity(0.08),
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),
                  
                  // Logo animado con tu imagen original
                  FadeTransition(
                    opacity: _fadeLogo,
                    child: SlideTransition(
                      position: _slideLogo,
                      child: Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accent.withOpacity(0.3),
                                AppColors.accent.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // TU LOGO ORIGINAL - REEMPLAZADO
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0.8, end: 1),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.asset(
                                        'assets/logo/app_icon.png',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.accentGradient,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.flight_takeoff_rounded,
                                              color: Colors.white,
                                              size: 48,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Efecto de anillo pulsante
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 1.0, end: 1.3),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return Container(
                                    width: 140 * value,
                                    height: 140 * value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.accent.withOpacity(0.2 * (2 - value)),
                                        width: 1.5,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Texto principal
                  FadeTransition(
                    opacity: _fadeText,
                    child: SlideTransition(
                      position: _slideText,
                      child: Column(
                        children: [
                          const Text(
                            'Aikōra Sora',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  blurRadius: 20,
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent.withOpacity(0.15),
                                  Colors.transparent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'Planifica viajes inteligentes\ncon ayuda de IA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Botones
                  FadeTransition(
                    opacity: _fadeButtons,
                    child: Column(
                      children: [
                        // Botón principal - Crear cuenta
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accent,
                                AppColors.accent.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRoutes.register),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch_rounded, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Botón secundario - Iniciar sesión
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.login),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Footer con efecto glass
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Text(
                            'Tu próxima aventura comienza aquí ✈️',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clase para las estrellas animadas
class Star {
  late double x;
  late double y;
  late double size;
  late double opacity;
  late double speed;
  
  Star() {
    final random = Random();
    x = random.nextDouble();
    y = random.nextDouble();
    size = 1 + random.nextDouble() * 2;
    opacity = 0.3 + random.nextDouble() * 0.7;
    speed = 0.5 + random.nextDouble() * 1.5;
  }
  
  void update(double progress) {
    // Animación sutil de parpadeo
    opacity = 0.3 + (sin(progress * 3.14159 * speed) + 1) / 2 * 0.5;
  }
}

class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final double progress;
  
  StarFieldPainter(this.stars, this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (var star in stars) {
      star.update(progress);
      paint.color = Colors.white.withOpacity(star.opacity);
      final x = star.x * size.width;
      final y = star.y * size.height;
      canvas.drawCircle(Offset(x, y), star.size, paint);
    }
    
    // Dibujar estrellas más grandes ocasionales
    paint.color = AppColors.accent.withOpacity(0.3 + sin(progress * 2) * 0.1);
    for (int i = 0; i < 5; i++) {
      final angle = progress * 2 + i;
      final x = size.width * (0.5 + cos(angle) * 0.4);
      final y = size.height * (0.3 + sin(angle * 1.3) * 0.2);
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}