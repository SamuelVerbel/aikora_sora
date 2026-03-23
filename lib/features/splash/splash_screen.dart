import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';

/// Pantalla de carga inicial de la app Se muestra durante ~4 segundos mientras:
/// - Se reproducen animaciones de entrada del logo.
/// - Se muestran mensajes rotativos de carga.
/// - Luego navega automáticamente al Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// TickerProviderStateMixin permite usar MÚLTIPLES AnimationControllers en el mismo State.
/// (SingleTickerProviderStateMixin solo permite uno.)
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controladores ────────────────────────────────────────────────────────
  // Cada controlador maneja un grupo de animaciones independiente.
  late AnimationController _entryController; // animación de entrada (1 vez)
  late AnimationController _floatController; // logo flotando (loop)
  late AnimationController _pulseController; // brillo pulsante (loop)

  // ── Animaciones derivadas ────────────────────────────────────────────────
  late Animation<double> _logoScale; // logo crece de 0 a 1 (bounce)
  late Animation<double> _logoFade; // logo aparece de transparente a opaco
  late Animation<double> _contentFade; // texto aparece con fade
  late Animation<Offset>  _contentSlide; // texto sube desde abajo
  late Animation<double> _floatY; // desplazamiento vertical del logo
  late Animation<double> _glowOpacity; // intensidad del anillo de luz

  // Índice del mensaje activo en la lista de mensajes rotativos
  int _messageIndex = 0;

  // Lista de mensajes que se muestran uno por uno durante la carga
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

    // Animación de entrada: dura 1.2 segundos, solo se ejecuta 1 vez
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    // Animación de flotación: 2.8 segundos, se repite en bucle
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true); // sube y baja continuamente

    // Animación de pulso: 1.6 segundos, se repite en bucle
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);

    // El logo escala de 0 a 1 con efecto "elástico" (rebote) entre 0% y 65% del entry
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    ));

    // El logo aparece con fade entre 0% y 35% del entry
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    ));

    // El texto aparece entre 45% y 85% del entry (después que el logo)
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.45, 0.85, curve: Curves.easeIn)));

    // El texto sube desde Offset(0, 0.4) = 40% abajo hasta su posición normal
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOut),
    ));

    // El logo se mueve entre -7 y +7 píxeles verticales (efecto levitación)
    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    // El brillo varía entre opacidad 0.2 y 0.65 (efecto respiración)
    _glowOpacity = Tween<double>(begin: 0.2, end: 0.65).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _runSequence(); // inicia la secuencia principal
  }

  /// Secuencia principal del Splash:
  /// 1. Pequeña pausa inicial.
  /// 2. Lanza la animación de entrada.
  /// 3. Rota los mensajes cada 680ms.
  /// 4. Navega al Home al terminar.
  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) _entryController.forward();

    // Avanza el mensaje visible uno por uno
    for (int i = 1; i < _messages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 680));
      if (mounted) setState(() => _messageIndex = i);
    }

    // Pausa final antes de navegar
    await Future.delayed(const Duration(milliseconds: 700));
    // pushReplacementNamed evita que el usuario pueda volver al splash con "atrás"
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.authGate);
  }

  @override
  void dispose() {
    // Liberar los 3 controladores para evitar fugas de memoria
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
        // Fondo degradado oscuro de arriba izquierda a abajo derecha
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
              const Spacer(flex: 2), // empuja el logo hacia el centro

              // ── Logo animado ────────────────────────────────────────────
              // AnimatedBuilder escucha los 3 controladores a la vez con Listenable.merge
              AnimatedBuilder(
                animation: Listenable.merge(
                    [_entryController, _floatController, _pulseController]),
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _logoFade,
                    child: Transform.translate(
                      offset: Offset(0, _floatY.value), // efecto levitación
                      child: Transform.scale(
                        scale: _logoScale.value, // bounce de entrada
                        child: Stack(
                          alignment: Alignment.center,
                          children: [ // Anillo exterior del glow (más grande y transparente)
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent
                                    .withOpacity(_glowOpacity.value * 0.18),
                              ),
                            ),
                            // Anillo interior del glow
                            Container(
                              width: 148,
                              height: 148,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent
                                    .withOpacity(_glowOpacity.value * 0.12),
                              ),
                            ),
                            // Círculo blanco con el logo real de la app
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

              // ── Nombre y tagline (entran con fade + slide) ──────────────
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

              // ── Mensajes rotativos + wave loader ───────────────────────
              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    // AnimatedSwitcher reemplaza el texto con fade+slide al cambiar
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
                      // ValueKey obliga a AnimatedSwitcher a detectar el cambio
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
                    const _WaveLoader(), // barras animadas tipo ecualizador
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
/// Widget de carga tipo "ecualizador de audio":
/// 5 barras verticales que suben y bajan con desfase entre sí.
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

    // Crea 5 controladores, cada uno con duración ligeramente distinta
    // para que las barras no se muevan al mismo tiempo (efecto ola)
    _ctrls = List.generate(
      5,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 440 + i * 75),
      )..repeat(reverse: true),
    );

    // Cada barra crece de 4px a 22px de alto
    _anims = List.generate(
      5,
      (i) => Tween<double>(begin: 4, end: 22).animate(
        CurvedAnimation(parent: _ctrls[i], curve: Curves.easeInOut),
      ),
    );

    // Desfase inicial: cada barra arranca con 95ms de retraso
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 95), () {
        if (mounted) _ctrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    // Liberar todos los controladores de las barras
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
            height: _anims[i].value, // alto dinámico según animación
            decoration: BoxDecoration(
              // más alta la barra = más opaca (efecto luminosidad)
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
