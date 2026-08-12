import 'package:flutter/material.dart';

class AppColors {
  // Custom Theme Colors (Black, Gold & Minimal Purple Accent)
  static const Color black = Color(0xFF000000); // Pure Black Background
  static const Color deepVoid = Color(0xFF0A0A0C); // Dark obsidian surface
  static const Color deepPurple = Color(0xFF1F0B2E); // Very dark purple/indigo surface (for minor details)
  
  static const Color sunGold = Color(0xFFFFB700); // Primary Golden Yellow
  static const Color sunAmber = Color(0xFFFF8A00); // Warm Amber Orange
  static const Color sunYellow = Color(0xFFFFD600); // Bright Yellow
  
  static const Color purpleAccent = Color(0xFF9B51E0); // Minimal Purple Accent
  static const Color darkPurpleAccent = Color(0xFF5E2B97); // Darker purple highlight
  static const Color paleGold = Color(0xFFFFF2D1); // Soft warm/golden white text
  
  // Sunburst Gradient
  static const LinearGradient sunburstGradient = LinearGradient(
    colors: [sunYellow, sunGold, sunAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary and Secondary
  static const Color primary = sunGold; // Glowing gold/yellow elements
  static const Color secondary = deepVoid; // Solid dark surfaces
  static const Color tertiary = Color(0xFF141416); // Elevated dark surface
  
  // Backgrounds
  static const Color background = black;

  // Text Colors
  static const Color textPrimary = paleGold; // Soft warm white text
  static const Color textSecondary = sunGold; // Gold accents for text
  static const Color textWhite = Colors.white; // Pure white

  // Accent Colors
  static const Color accent = purpleAccent; // Minimal purple accent
  
  // Status Colors
  static const Color success = Color(0xFF00FF9D); // Neon green
  static const Color warning = sunAmber; // Sunset orange
  static const Color error = Color(0xFFFF3B30); // Vibrant error red

  // Divider and Border Colors
  static const Color divider = Color(0x33FFB700); // Translucent gold divider
  static const Color border = sunGold; // Solid gold borders

  // Shadow
  static const Color shadow = sunGold; // Gold glow shadow

  // Transparent
  static const Color transparent = Colors.transparent;
}
