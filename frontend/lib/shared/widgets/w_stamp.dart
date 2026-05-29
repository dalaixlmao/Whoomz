import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Passport-style stamp with the W glyph.
class WStamp extends StatelessWidget {
  const WStamp({
    super.key,
    this.size = 64,
    this.color = AppColors.accent,
    this.rotateDegrees = -8,
    this.label,
  });

  final double size;
  final Color color;
  final double rotateDegrees;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotateDegrees * 3.14159265 / 180,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _WStampPainter(color: color, label: label),
        ),
      ),
    );
  }
}

class _WStampPainter extends CustomPainter {
  const _WStampPainter({required this.color, this.label});
  final Color color;
  final String? label;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    final outerRingPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.031;

    final innerRingPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.01;

    canvas.drawCircle(Offset(cx, cy), r, outerRingPaint);

    const dashCount = 20;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        final start = 2 * 3.14159265 * i / dashCount;
        final end = 2 * 3.14159265 * (i + 0.5) / dashCount;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.86),
          start, end - start, false, innerRingPaint,
        );
      }
    }

    // W glyph — scaled path from SVG: M16 27 L26 56 L34 38 L40 56 L48 38 L54 56 L64 27 on 80×80
    final wPaint = Paint()
      ..color = color.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.056
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.width / 80;
    final wPath = Path()
      ..moveTo(16 * s, 27 * s)
      ..lineTo(26 * s, 56 * s)
      ..lineTo(34 * s, 38 * s)
      ..lineTo(40 * s, 56 * s)
      ..lineTo(48 * s, 38 * s)
      ..lineTo(54 * s, 56 * s)
      ..lineTo(64 * s, 27 * s);

    canvas.drawPath(wPath, wPaint);

    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: size.width * 0.09,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.75),
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(cx - textPainter.width / 2, size.height * 0.86));
    }
  }

  @override
  bool shouldRepaint(_WStampPainter old) =>
      old.color != color || old.label != label;
}
