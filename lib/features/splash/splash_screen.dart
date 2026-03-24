import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';

/// Pantalla de carga inicial con animaciones premium y estrellas de fondo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _starController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _floatY;
  late Animation<double> _glowOpacity;
  
  late List<Star> _stars;
  int _messageIndex = 0;
  
  final List<String> _messages = [
    '✈️  Cargando destinos increíbles...',
    '🗺️  Preparando tu aventura...',
    '🌏  Explorando el mundo para ti...',
    '🤖  Activando asistente IA...',
    '🏝️  Listo para despegar...',
  ];

  @override
  void initState() {
    super.initState();
    _stars = List.generate(60, (index) => Star());
    
    _entryController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1200),
    );
    
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

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeIn),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.45, 0.95, curve: Curves.easeOut),
      ),
    );

    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowOpacity = Tween<double>(begin: 0.2, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) _entryController.forward();

    for (int i = 1; i < _messages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 680));
      if (mounted) setState(() => _messageIndex = i);
    }

    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.authGate);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente premium y estrellas
          AnimatedBuilder(
            animation: _starController,
            builder: (context, _) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A0F1A),
                      Color(0xFF0F1A2A),
                      Color(0xFF0B1525),
                      Color(0xFF050A12),
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: CustomPaint(
                  painter: StarFieldPainter(_stars, _starController.value),
                  size: Size.infinite,
                ),
              );
            },
          ),
          
          // Efecto de brillo radial
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo animado con tu imagen original
                AnimatedBuilder(
                  animation: Listenable.merge(
                    [_entryController, _floatController, _pulseController],
                  ),
                  builder: (context, _) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: Transform.translate(
                        offset: Offset(0, _floatY.value),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Anillo exterior de glow
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent
                                      .withOpacity(_glowOpacity.value * 0.18),
                                ),
                              ),
                              // Anillo interior de glow
                              Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent
                                      .withOpacity(_glowOpacity.value * 0.12),
                                ),
                              ),
                              // Círculo con tu logo
                              Container(
                                width: 124,
                                height: 124,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent
                                          .withOpacity(_glowOpacity.value),
                                      blurRadius: 36,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(18),
                                child: Image.asset(
                                  'assets/logo/app_icon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.flight_takeoff_rounded,
                                      size: 50,
                                      color: AppColors.accent,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 38),
                
                // Nombre y tagline
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      children: [
                        const Text(
                          'Aikōra Sora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.8,
                            shadows: [
                              Shadow(
                                blurRadius: 20,
                                color: Colors.black26,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu copiloto de viajes inteligente',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 15,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Mensajes rotativos
                FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _messages[_messageIndex],
                          key: ValueKey(_messageIndex),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _PremiumWaveLoader(),
                      const SizedBox(height: 52),
                    ],
                  ),
                ),
              ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
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