import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';

class AmbientGlowBackground extends StatefulWidget {
  final Widget child;
  const AmbientGlowBackground({super.key, required this.child});

  @override
  State<AmbientGlowBackground> createState() => _AmbientGlowBackgroundState();
}

class _AmbientGlowBackgroundState extends State<AmbientGlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ValueNotifier<double> _timeNotifier = ValueNotifier(0.0);
  final List<_Firefly> _fireflies = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    double lastValue = 0.0;
    double accumulatedValue = 0.0;
    _controller.addListener(() {
      double currentValue = _controller.value;
      double delta = currentValue - lastValue;
      if (delta < 0) {
        delta += 1.0;
      }
      accumulatedValue += delta;
      lastValue = currentValue;
      _timeNotifier.value = accumulatedValue;
    });

    // Deterministic random generation for consistent layout
    final random = Random(42);
    for (int i = 0; i < 22; i++) {
      _fireflies.add(
        _Firefly(
          xRatio: random.nextDouble(),
          yRatio: random.nextDouble(),
          radius: 1.5 + random.nextDouble() * 2.5, // 1.5 to 4.0 pixels
          speed: 0.08 + random.nextDouble() * 0.12, // vertical speed ratio
          driftRange: 0.015 + random.nextDouble() * 0.025, // horizontal drift
          pulseSpeed: 1.5 + random.nextDouble() * 2.5, // pulsing rate
          phaseOffset: random.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // 1. Dark Background base
        Container(
          color: AppColors.background,
        ),

        // 2. Animated Glowing Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * pi;
            final pathT = t * 0.4;

            // Soft periodic color shifts using sine wave
            final colorShiftFactor1 = (sin(t) + 1.0) / 2.0;
            final colorShiftFactor2 = (cos(t) + 1.0) / 2.0;
            final colorShiftFactor3 = (sin(t + pi / 4) + 1.0) / 2.0;

            final orb1Color = Color.lerp(
              AppColors.primary,
              const Color(0xFFFFE57F), // Neon gold
              colorShiftFactor1,
            )!;

            final orb2Color = Color.lerp(
              AppColors.accent,
              const Color(0xFFD500F9), // Neon violet
              colorShiftFactor2,
            )!;

            final orb3Color = Color.lerp(
              AppColors.deepPurple,
              const Color(0xFF4A148C), // Vibrant purple
              colorShiftFactor3,
            )!;

            // Orb 1 (Gold/Primary) - Elliptical motion in top-right
            final orb1Scale = 1.0 + 0.15 * sin(t * 0.5);
            final orb1X = size.width * 0.45 + sin(pathT) * 160;
            final orb1Y = size.height * 0.12 + cos(pathT) * 130;

            // Orb 2 (Purple/Accent) - Elliptical motion in bottom-left
            final orb2Scale = 1.0 + 0.12 * cos(t * 0.7);
            final orb2X = size.width * 0.05 + cos(pathT + pi / 2) * 170;
            final orb2Y = size.height * 0.5 + sin(pathT + pi / 2) * 140;

            // Orb 3 (Deep Purple) - Smooth oscillation in center-right
            final orb3Scale = 1.0 + 0.18 * sin(t * 0.3);
            final orb3X = size.width * 0.35 + sin(pathT * 1.3) * 140;
            final orb3Y = size.height * 0.35 + cos(pathT * 1.3) * 140;

            return Stack(
              children: [
                // Gold Orb
                Positioned(
                  left: orb1X,
                  top: orb1Y,
                  child: Container(
                    width: 280 * orb1Scale,
                    height: 280 * orb1Scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: orb1Color.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                // Accent Purple Orb
                Positioned(
                  left: orb2X,
                  top: orb2Y,
                  child: Container(
                    width: 320 * orb2Scale,
                    height: 320 * orb2Scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: orb2Color.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                // Deep Purple Orb
                Positioned(
                  left: orb3X,
                  top: orb3Y,
                  child: Container(
                    width: 340 * orb3Scale,
                    height: 340 * orb3Scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: orb3Color.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // 3. Blur filter to merge shapes into a smooth ambient field
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        // 4. Subtle fireflies layered on top of blurred background
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _timeNotifier,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FirefliesPainter(
                    fireflies: _fireflies,
                    animationValue: _timeNotifier.value,
                  ),
                );
              },
            ),
          ),
        ),

        // 5. Subtle radial vignette overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 6. Foreground content
        widget.child,
      ],
    );
  }
}

class _Firefly {
  final double xRatio;
  final double yRatio;
  final double radius;
  final double speed;
  final double driftRange;
  final double pulseSpeed;
  final double phaseOffset;

  _Firefly({
    required this.xRatio,
    required this.yRatio,
    required this.radius,
    required this.speed,
    required this.driftRange,
    required this.pulseSpeed,
    required this.phaseOffset,
  });
}

class _FirefliesPainter extends CustomPainter {
  final List<_Firefly> fireflies;
  final double animationValue;

  _FirefliesPainter({required this.fireflies, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (var f in fireflies) {
      // Float Y slowly upwards
      double y = (f.yRatio - (animationValue * f.speed)) % 1.0;

      // Horizontal wave drift
      double drift = sin(animationValue * 2 * pi * f.pulseSpeed + f.phaseOffset) * f.driftRange;
      double x = (f.xRatio + drift) % 1.0;

      // Opacity pulsing
      double pulse = (sin(animationValue * 2 * pi * f.pulseSpeed * 2.2 + f.phaseOffset) + 1.0) / 2.0;
      double opacity = 0.1 + pulse * 0.5; // range: 0.1 to 0.6

      final screenX = x * size.width;
      final screenY = y * size.height;

      // Draw soft outer glow
      final glowPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.radius * 1.5);
      canvas.drawCircle(Offset(screenX, screenY), f.radius * 2.0, glowPaint);

      // Draw gold body
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.radius * 0.4);
      canvas.drawCircle(Offset(screenX, screenY), f.radius, paint);

      // Draw tiny white core for brightness
      final corePaint = Paint()..color = Colors.white.withValues(alpha: opacity * 0.85);
      canvas.drawCircle(Offset(screenX, screenY), f.radius * 0.35, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FirefliesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
