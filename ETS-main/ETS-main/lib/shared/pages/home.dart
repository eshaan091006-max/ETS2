import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/models/contingent.dart';

class Home extends StatefulWidget {
  final Contingent? contingent;
  const Home({required this.contingent, super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // Transparent background so AmbientGlowBackground shows through
      child: Center(
        child: AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Welcome Text Container with premium neon aura
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    // Radial gradient to simulate a soft ambient glowing halo behind the text
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.18),  // Purple core glow
                        AppColors.primary.withValues(alpha: 0.06), // Outer gold glow
                        Colors.transparent,                  // Fades to black
                      ],
                      radius: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.contingent != null) ...[
                        Text(
                          "Welcome",
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 42,
                            letterSpacing: 3.0,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withValues(alpha: 0.9), // Glowing gold
                                blurRadius: 15,
                              ),
                              Shadow(
                                color: AppColors.accent.withValues(alpha: 0.7), // Glowing purple
                                blurRadius: 25,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.contingent!.contingentCode,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary, // Gold text
                            fontSize: 48,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: AppColors.accent.withValues(alpha: 0.9), // Purple glow
                                blurRadius: 20,
                              ),
                              Shadow(
                                color: AppColors.primary.withValues(alpha: 0.5), // Gold glow
                                blurRadius: 35,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          "Admin Portal",
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 42,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                blurRadius: 15,
                              ),
                              Shadow(
                                color: AppColors.accent.withValues(alpha: 0.7),
                                blurRadius: 25,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                
                // Central Logo area (Static with pulsating neon glow)
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final glowScale = 0.85 + 0.15 * _glowController.value;
                    final opacity = 0.3 + 0.7 * _glowController.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsating Neon Glow Background
                        Container(
                          width: 180 * glowScale,
                          height: 180 * glowScale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFB83280).withValues(alpha: 0.4 * opacity), // Pulsating Pink core
                                AppColors.primary.withValues(alpha: 0.12 * opacity),       // Pulsating Gold outer
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                  child: Image.asset(
                    'assets/logo/malhar26_logo.png',
                    width: 220,
                    height: 220,
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
