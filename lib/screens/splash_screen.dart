import 'package:flutter/material.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _rotateController;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _rotateAnim = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.elasticOut),
    );

    _launchSequence();
  }

  Future<void> _launchSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    _rotateController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBrown,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [AppTheme.mediumBrown, AppTheme.darkBrown],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              AnimatedBuilder(
                animation: Listenable.merge([_scaleAnim, _glowAnim, _rotateAnim]),
                builder: (context, _) {
                  return Transform.scale(
                    scale: _scaleAnim.value,
                    child: Transform.rotate(
                      angle: _rotateAnim.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardDark,
                          border: Border.all(
                            color: AppTheme.gold.withOpacity(_glowAnim.value),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryOrange
                                  .withOpacity(_glowAnim.value * 0.7),
                              blurRadius: 50,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: AppTheme.gold
                                  .withOpacity(_glowAnim.value * 0.3),
                              blurRadius: 80,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const _CabanaLogo(size: 180),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 36),

              // Nombre del restaurante animado
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: AppTheme.gold, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'R E S T O B A R',
                          style: TextStyle(
                            color: AppTheme.gold.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: AppTheme.gold, size: 14),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'La Cabaña',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                              color: AppTheme.primaryOrange, blurRadius: 20),
                        ],
                      ),
                    ),
                    const Text(
                      'del Sabor',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 30,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(color: AppTheme.gold, blurRadius: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Puntos de carga
              FadeTransition(
                opacity: _fadeAnim,
                child: const _BouncingDots(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logo dentro del círculo ─────────────────────────────────────────────────

class _CabanaLogo extends StatelessWidget {
  final double size;
  const _CabanaLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cabin, color: AppTheme.gold, size: 70),
        const SizedBox(height: 4),
        const Text(
          'La Cabaña',
          style: TextStyle(
            color: AppTheme.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Text(
          'del Sabor',
          style: TextStyle(
            color: AppTheme.primaryOrange,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ─── Puntos de carga animados ─────────────────────────────────────────────────

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_controller.value - i * 0.25) % 1.0).clamp(0.0, 1.0);
            final bounce = (offset < 0.5 ? offset * 2 : (1 - offset) * 2);
            return AnimatedContainer(
              duration: Duration.zero,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 10,
              height: 10,
              transform: Matrix4.translationValues(0, -bounce * 12, 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange.withOpacity(0.4 + bounce * 0.6),
              ),
            );
          }),
        );
      },
    );
  }
}
