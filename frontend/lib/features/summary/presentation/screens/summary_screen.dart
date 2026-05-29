import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/calorie_arc.dart';
import '../../../../shared/widgets/w_mark.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final label = '${weekdays[today.weekday - 1]}, ${months[today.month - 1]} ${today.day}';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("TODAY'S ENTRY",
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.inkWithOpacity(0.4), letterSpacing: 1.8,
                          )),
                        const SizedBox(height: 2),
                        Text(label,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22, fontWeight: FontWeight.w800,
                            color: AppColors.ink, letterSpacing: -0.5, height: 1.1,
                          )),
                      ],
                    ),
                    IconButton(
                      onPressed: () => context.go('/app/home'),
                      icon: const Icon(Icons.close_rounded, color: AppColors.ink, size: 22),
                    ),
                  ],
                ),
              ),

              // Hero arc
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CalorieArc(value: 1420, target: 2000, accent: AppColors.accent, size: 250),
                ),
              ),

              // Deficit pill
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentWithOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '580 kcal under',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12.5, fontWeight: FontWeight.w700,
                      color: AppColors.accent, letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    for (final s in [
                      ('P', '72g', const Color(0xFFE67E22)),
                      ('👣', '8,412', const Color(0xFF3498DB)),
                      ('💧', '2.4L', const Color(0xFF5DADE2)),
                    ])
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: s.$1 == '💧' ? 0 : 10),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bubbleAI,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.inkWithOpacity(0.08)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  color: s.$3.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: s.$1.length == 1 && s.$1.codeUnitAt(0) < 256
                                      ? Text(s.$1, style: GoogleFonts.bricolageGrotesque(fontSize: 14, fontWeight: FontWeight.w800, color: s.$3))
                                      : Text(s.$1, style: const TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(s.$2, style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3)),
                              Text(
                                switch (s.$1) { 'P' => 'Protein', '👣' => 'Steps', _ => 'Water' },
                                style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkWithOpacity(0.47), letterSpacing: 0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // AI insight
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.bubbleAI,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.inkWithOpacity(0.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WMark(size: 32, color: AppColors.accent, bgColor: Color(0x1A5C2D91)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WHOOMZ SAYS',
                              style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(
                              'Light on carbs today — solid deficit. Keep it up! 🥗',
                              style: GoogleFonts.bricolageGrotesque(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.45, letterSpacing: -0.1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Share button
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cream,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text('Save story card to camera roll',
                      style: GoogleFonts.bricolageGrotesque(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
