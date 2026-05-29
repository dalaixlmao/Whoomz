import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Inline nutrition receipt stamp shown inside AI bubbles.
class NutritionStamp extends StatelessWidget {
  const NutritionStamp({
    super.key,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.accent = AppColors.accent,
  });

  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.bricolageGrotesque(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: accent,
    );
    final dot = Text('·', style: style.copyWith(color: accent.withValues(alpha: 0.4)));

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '~$kcal',
            style: style.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          Text('kcal', style: style.copyWith(color: accent.withValues(alpha: 0.55), fontWeight: FontWeight.w500)),
          dot,
          Text('P ${proteinG}g', style: style),
          dot,
          Text('C ${carbsG}g', style: style),
          dot,
          Text('F ${fatG}g', style: style),
        ],
      ),
    );
  }
}
