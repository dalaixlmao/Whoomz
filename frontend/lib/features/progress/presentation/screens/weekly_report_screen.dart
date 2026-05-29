import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/whoomz_wordmark.dart';
import '../../../../shared/widgets/w_mark.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.chevron_left_rounded, color: AppColors.cream),
                      label: Text('Back', style: GoogleFonts.bricolageGrotesque(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.cream)),
                    ),
                    Text('POSTCARD',
                      style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: AppColors.cream.withValues(alpha: 0.6))),
                  ],
                ),
              ),

              // Postcard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Transform.rotate(
                  angle: -0.021, // -1.2°
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 50, offset: const Offset(0, 20)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Watermark W
                        Positioned(
                          right: -20, top: -10,
                          child: Opacity(
                            opacity: 0.06,
                            child: WMark(size: 220, color: AppColors.ink),
                          ),
                        ),
                        // Perforated divider
                        Positioned(
                          left: 0, top: 0, bottom: 0,
                          child: FractionallySizedBox(
                            widthFactor: 0.38,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomPaint(
                                size: const Size(1, double.infinity),
                                painter: _DashedLinePainter(),
                              ),
                            ),
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Week of May 11 – May 17',
                              style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkWithOpacity(0.55), letterSpacing: 1.6)),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: 'Your week,\nWhoomz-style ',
                                  style: GoogleFonts.bricolageGrotesque(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.6, height: 1.05),
                                ),
                                const TextSpan(text: '🎨', style: TextStyle(fontSize: 22)),
                              ]),
                            ),

                            const SizedBox(height: 22),

                            // Stats grid
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 2.8,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              children: [
                                _statCell('Days logged', '6/7'),
                                _statCell('Avg calories', '1,908'),
                                _statCell('Most active', 'Saturday'),
                                _statCell('Streak', '7 🔥'),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // AI message
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.accentWithOpacity(0.1),
                                border: Border.all(color: AppColors.accentWithOpacity(0.25), width: 1.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const WMark(size: 20, color: AppColors.accent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'You showed up six out of seven days. That\'s not a streak — that\'s a habit. Quiet, steady, real. See you next week. 🎨',
                                      style: GoogleFonts.bricolageGrotesque(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.4, letterSpacing: -0.05, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Addressee + stamp
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('FOR', style: GoogleFonts.bricolageGrotesque(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkWithOpacity(0.4), letterSpacing: 1.4)),
                                    const SizedBox(height: 2),
                                    Text('Aanya', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3)),
                                  ],
                                ),
                                _buildStamp(),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Share button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cream,
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                    ),
                    child: Text('Share story 🎨',
                      style: GoogleFonts.bricolageGrotesque(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: AppColors.ink)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('exports as 9:16 instagram story',
                style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: AppColors.cream.withValues(alpha: 0.4))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: GoogleFonts.bricolageGrotesque(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkWithOpacity(0.4), letterSpacing: 1.4)),
        const SizedBox(height: 2),
        Text(value,
          style: GoogleFonts.bricolageGrotesque(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5, height: 1.1)),
      ],
    );
  }

  Widget _buildStamp() {
    return Container(
      width: 64, height: 78,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WhoomzWordmark(size: 11, color: Colors.white, accentColor: Colors.white),
          const WMark(size: 28, color: Colors.white),
          Text('7-DAY STREAK',
            style: GoogleFonts.bricolageGrotesque(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkWithOpacity(0.25)
      ..strokeWidth = 1.5;

    const dashH = 4.0;
    const gapH = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashH), paint);
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}
