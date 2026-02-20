import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';

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

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _contentFade;
  late Animation<Offset>  _contentSlide;
  late Animation<double> _floatY;
  late Animation<double> _glowOpacity;

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

    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    ));

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    ));

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.45, 0.85, curve: Curves.easeIn)));

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOut),
    ));

    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _glowOpacity = Tween<double>(begin: 0.2, end: 0.65).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

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
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1C2D), Color(0xFF0F2744), Color(0xFF091520)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Logo con floating + pulse ─────────────────────
              AnimatedBuilder(
                animation: Listenable.merge(
                    [_entryController, _floatController, _pulseController]),
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
                            // Outer glow ring
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent
                                    .withOpacity(_glowOpacity.value * 0.18),
                              ),
                            ),
                            // Inner glow ring
                            Container(
                              width: 148,
                              height: 148,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent
                                    .withOpacity(_glowOpacity.value * 0.12),
                              ),
                            ),
                            // Logo blanco
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

              // ── Nombre y tagline ──────────────────────────────
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu copiloto de viajes inteligente',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Mensajes rotativos + wave loader ─────────────
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
                    const _WaveLoader(),
                    const SizedBox(height: 52),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wave Loader ───────────────────────────────────────────────────────────────

class _WaveLoader extends StatefulWidget {
  const _WaveLoader();

  @override
  State<_WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<_WaveLoader> with TickerProviderStateMixin {
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
              color: AppColors.accent
                  .withOpacity(0.35 + (_anims[i].value / 22) * 0.65),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
