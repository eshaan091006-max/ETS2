import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/glass_container.dart';

class NeonContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;

  const NeonContainer({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
    this.padding,
    this.margin,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? AppColors.primary;
    return LiquidGlassContainer(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      glowColor: effectiveGlowColor,
      child: child,
    );
  }
}
