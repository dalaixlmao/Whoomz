import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// The WHOOMZ wordmark — "WHOOM" in ink, "Z" in accent with a motion trail.
class WhoomzWordmark extends StatelessWidget {
  const WhoomzWordmark({
    super.key,
    this.size = 28,
    this.color = AppColors.ink,
    this.accentColor = AppColors.accent,
  });

  final double size;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'WHOOM',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -size * 0.025,
            height: 1,
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              'Z',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: size,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: -size * 0.025,
                height: 1,
              ),
            ),
            Positioned(
              bottom: -size * 0.12,
              right: 0,
              child: CustomPaint(
                size: Size(size * 1.2, size * 0.35),
                painter: _TrailPainter(color: accentColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.85)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.38
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.48)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.26
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(0, size.height * 0.33)
      ..quadraticBezierTo(size.width * 0.35, 0, size.width, size.height * 0.4);

    final path2 = Path()
      ..moveTo(size.width * 0.15, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.7, size.width, size.height);

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.color != color;
}
