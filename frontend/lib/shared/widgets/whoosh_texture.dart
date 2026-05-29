import 'package:flutter/material.dart';

/// Soft curved background texture — matches the WhooshTexture from brand.jsx.
class WhooshTexture extends StatelessWidget {
  const WhooshTexture({super.key, this.color = const Color(0xFF5C2D91), this.opacity = 0.06});

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _WhooshPainter(color: color, opacity: opacity),
        ),
      ),
    );
  }
}

class _WhooshPainter extends CustomPainter {
  const _WhooshPainter({required this.color, required this.opacity});
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void drawCurve(double startY, double ctrlY, double endY, double strokeW, double alpha) {
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0), color.withValues(alpha: opacity * alpha)],
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(-20, startY * h)
        ..quadraticBezierTo(w * 0.5, ctrlY * h, w + 20, endY * h);

      canvas.drawPath(path, paint);
    }

    drawCurve(0.33, 0.17, 0.5, h * 0.16, 3.0);
    drawCurve(0.58, 0.42, 0.75, h * 0.12, 2.0);
    drawCurve(0.83, 0.67, 1.0, h * 0.08, 1.0);
  }

  @override
  bool shouldRepaint(_WhooshPainter old) =>
      old.color != color || old.opacity != opacity;
}
