import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';

final ThemeData themeData = ThemeData(
  useMaterial3: true,
  textTheme: GoogleFonts.interTextTheme().apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  ).copyWith(
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textSecondary),
    labelLarge: TextStyle(color: AppColors.textWhite),
  ),

  // 🔹 Scaffold & Primary Colors
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.secondary,
    error: AppColors.error,
    onPrimary: AppColors.textWhite,
    onSecondary: AppColors.textPrimary,
    onSurface: AppColors.textSecondary,
    onError: AppColors.textWhite,
  ),

  // 🔹 AppBar (if needed globally)
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textWhite,
    elevation: 0,
    titleTextStyle: GoogleFonts.montserrat(
      color: AppColors.textWhite,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),

  // 🔹 TextField
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.tertiary,
    hintStyle: TextStyle(color: AppColors.textSecondary),
    labelStyle: TextStyle(color: AppColors.textPrimary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.accent, width: 2),
    ),
  ),

  // 🔹 DropdownButton (FormField)
  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.secondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
    ),
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(AppColors.secondary),
      shadowColor: WidgetStateProperty.all(AppColors.shadow),
    ),
    textStyle: TextStyle(color: AppColors.textPrimary),
  ),

  // 🔹 ElevatedButton
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.textWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),

  // 🔹 BottomSheet
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.secondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    elevation: 10,
    modalBackgroundColor: AppColors.secondary,
  ),

  // 🔹 Dialog
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.secondary,
    titleTextStyle: GoogleFonts.montserrat(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    contentTextStyle: TextStyle(fontSize: 16, color: AppColors.textSecondary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);
