import 'package:flutter/material.dart';

class AppColors {
  static const Color cream = Color(0xFFFAF5EC);
  static const Color heroCard = Color(0xFFFFFCF5);
  static const Color bubbleAI = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1F1812);
  static const Color accent = Color(0xFF5C2D91);
  static const Color coral = Color(0xFFFF5733);
  static const Color streakOrange = Color(0xFFFF6B35);
  static const Color green = Color(0xFF22C55E);
  static const Color muted = Color(0x99261810);

  static Color inkWithOpacity(double opacity) =>
      const Color(0xFF1F1812).withValues(alpha: opacity);

  static Color accentWithOpacity(double opacity) =>
      const Color(0xFF5C2D91).withValues(alpha: opacity);
}
