// lib/core/widgets/loading_overlay.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_colors.dart';

/// Overlay de carga premium con animación de estrellas y mensajes rotativos
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;
  static int _activeCount = 0;

  /// Muestra el overlay de carga con mensaje opcional
  static void show(BuildContext context, {String? message}) {
    if (_isShowing) {
      _activeCount++;
      return;
    }

    _activeCount = 1;
    _isShowing = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayWidget(
        message: message ?? 'Cargando...',
        onDismiss: () => _cleanup(),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Oculta el overlay de carga
  static void hide() {
    if (_activeCount > 1) {
      _activeCount--;
      return;
    }

    _cleanup();
  }

  static void _cleanup() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isShowing = false;
    _activeCount = 0;
  }
}

class _LoadingOverlayWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _LoadingOverlayWidget({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_LoadingOverlayWidget> createState() => _LoadingOverlayWidgetState();
}

class _LoadingOverlayWidgetState extends State<_LoadingOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _starController;
  late Animation<double> _floatY;
  late Animation<double> _glowOpacity;
  late List<Star> _stars;
  int _messageIndex = 0;
  late List<String> _messages;

  final List<String> _defaultMessages = [
    '✨ Preparando tu experiencia...',
    '🌍 Explorando el mundo...',
    '🤖 IA procesando...',
    '🚀 Casi listo...',
    '⭐ Finalizando...',
  ];

  @override
  void initState() {
    super.initState();
    
    // Si el mensaje viene vacío, usamos los rotativos
    _messages = widget.message.isEmpty ? _defaultMessages : [widget.message];
    
    _stars = List.generate(40, (index) => Star());
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _floatY = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowOpacity = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotar mensajes si son múltiples
    if (_messages.length > 1) {
      Future<void>.delayed(const Duration(milliseconds: 1200)).then((_) {
        _startMessageRotation();
      });
    }
  }

  void _startMessageRotation() {
    Future<void>.delayed(const Duration(milliseconds: 800), _rotateMessage);
  }

  void _rotateMessage() {
    if (!mounted) return;
    setState(() {
      _messageIndex = (_messageIndex + 1) % _messages.length;
    });
    Future<void>.delayed(const Duration(milliseconds: 800), _rotateMessage);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Fondo oscuro semitransparente con blur
          Container(
            color: Colors.black.withOpacity(0.85),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Estrellas animadas
          AnimatedBuilder(
            animation: _starController,
            builder: (context, _) {
              return CustomPaint(
                painter: StarFieldPainter(_stars, _starController.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Efecto de brillo radial
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppColors.accent.withOpacity(0.05),
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Contenido centrado
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatController, _pulseController]),
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0, _floatY.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo animado
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Anillo de glow
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent
                                  .withOpacity(_glowOpacity.value * 0.15),
                            ),
                          ),
                          // Círculo con logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent
                                      .withOpacity(_glowOpacity.value * 0.8),
                                  blurRadius: 25,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Image.asset(
                              'assets/logo/app_icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.flight_takeoff_rounded,
                                  size: 40,
                                  color: AppColors.accent,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Mensaje animado
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _messages[_messageIndex],
                          key: ValueKey(_messageIndex),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Wave loader premium
                      const _PremiumWaveLoader(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wave Loader Premium ───────────────────────────────────────────────────────
class _PremiumWaveLoader extends StatefulWidget {
  const _PremiumWaveLoader();

  @override
  State<_PremiumWaveLoader> createState() => _PremiumWaveLoaderState();
}

class _PremiumWaveLoaderState extends State<_PremiumWaveLoader>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      5,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 440 + i * 75),
      )..repeat(reverse: true),
    );

    _anims = List.generate(
      5,
      (i) => Tween<double>(begin: 4, end: 22).animate(
        CurvedAnimation(parent: _ctrls[i], curve: Curves.easeInOut),
      ),
    );

    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 95), () {
        if (mounted) _ctrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 5,
            height: _anims[i].value,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent,
                  AppColors.accent.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

// ── Clase para las estrellas animadas ────────────────────────────────────────
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