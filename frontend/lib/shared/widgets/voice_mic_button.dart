import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class VoiceMicButton extends StatelessWidget {
  const VoiceMicButton({
    super.key,
    required this.recording,
    required this.onTap,
    this.accent = AppColors.accent,
    this.size = 56,
  });

  final bool recording;
  final VoidCallback onTap;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recording ? accent : Colors.transparent,
          border: recording ? null : Border.all(color: accent, width: 2),
          boxShadow: recording
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: CustomPaint(
            size: Size(size * 0.42, size * 0.42),
            painter: _MicPainter(color: recording ? Colors.white : accent),
          ),
        ),
      ),
    );
  }
}

class _MicPainter extends CustomPainter {
  const _MicPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Mic body
    final micRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.375, 0, w * 0.25, h * 0.54),
      Radius.circular(w * 0.125),
    );
    canvas.drawRRect(micRect, fillPaint);

    // Arc
    final arcPath = Path()
      ..moveTo(w * 0.21, h * 0.46)
      ..quadraticBezierTo(w * 0.21, h * 0.79, w * 0.5, h * 0.79)
      ..quadraticBezierTo(w * 0.79, h * 0.79, w * 0.79, h * 0.46);
    canvas.drawPath(arcPath, paint);

    // Stem
    canvas.drawLine(Offset(w * 0.5, h * 0.79), Offset(w * 0.5, h), paint);
  }

  @override
  bool shouldRepaint(_MicPainter old) => old.color != color;
}
