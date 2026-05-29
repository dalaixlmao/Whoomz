import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        surface: AppColors.cream,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bubbleAI,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.inkWithOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.inkWithOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
        ),
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 42, fontWeight: FontWeight.w800,
        color: AppColors.ink, letterSpacing: -1.6, height: 1.0,
      ),
      displayMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 34, fontWeight: FontWeight.w800,
        color: AppColors.ink, letterSpacing: -1.0, height: 1.05,
      ),
      displaySmall: GoogleFonts.bricolageGrotesque(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: AppColors.ink, letterSpacing: -0.7, height: 1.1,
      ),
      headlineLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 24, fontWeight: FontWeight.w800,
        color: AppColors.ink, letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: AppColors.ink, letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: AppColors.ink, letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: AppColors.ink, letterSpacing: -0.1,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.ink, height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.ink, height: 1.45,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.ink,
      ),
      labelLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: AppColors.ink, letterSpacing: 0.8,
      ),
      labelSmall: GoogleFonts.bricolageGrotesque(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.ink, letterSpacing: 1.2,
      ),
    );
  }
}
