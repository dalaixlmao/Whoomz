import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakFlame extends StatelessWidget {
  const StreakFlame({
    super.key,
    required this.count,
    this.accent = const Color(0xFFFF6B35),
    this.size = 18,
  });

  final int count;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _FlamePainter(color: accent),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: size - 1,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer flame
    final outerPaint = Paint()..color = color..style = PaintingStyle.fill;
    final outerPath = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.54, h * 0.25, w * 0.67, h * 0.29, w * 0.67, h * 0.46)
      ..cubicTo(w * 0.67, h * 0.5, w * 0.65, h * 0.54, w * 0.58, h * 0.54)
      ..cubicTo(w * 0.58, h * 0.42, w * 0.54, h * 0.38, w * 0.5, h * 0.33)
      ..cubicTo(w * 0.48, h * 0.46, w * 0.33, h * 0.5, w * 0.33, h * 0.67)
      ..cubicTo(w * 0.33, h * 0.80, w * 0.42, h * 0.92, w * 0.5, h * 0.92)
      ..cubicTo(w * 0.58, h * 0.92, w * 0.71, h * 0.80, w * 0.71, h * 0.65)
      ..cubicTo(w * 0.71, h * 0.50, w * 0.63, h * 0.42, w * 0.58, h * 0.29)
      ..cubicTo(w * 0.56, h * 0.19, w * 0.52, h * 0.125, w * 0.5, 0)
      ..close();
    canvas.drawPath(outerPath, outerPaint);

    // Inner highlight
    final innerPaint = Paint()..color = const Color(0xFFFFD93D)..style = PaintingStyle.fill;
    final innerPath = Path()
      ..moveTo(w * 0.5, h * 0.46)
      ..cubicTo(w * 0.52, h * 0.54, w * 0.56, h * 0.58, w * 0.56, h * 0.67)
      ..cubicTo(w * 0.56, h * 0.75, w * 0.52, h * 0.79, w * 0.5, h * 0.79)
      ..cubicTo(w * 0.46, h * 0.79, w * 0.42, h * 0.75, w * 0.42, h * 0.69)
      ..cubicTo(w * 0.42, h * 0.58, w * 0.48, h * 0.54, w * 0.5, h * 0.46)
      ..close();
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.color != color;
}
