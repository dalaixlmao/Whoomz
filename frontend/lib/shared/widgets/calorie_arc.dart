import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// The hero calorie arc — 220° open arc showing progress toward a target.
class CalorieArc extends StatelessWidget {
  const CalorieArc({
    super.key,
    required this.value,
    required this.target,
    this.accent = AppColors.accent,
    this.size = 240,
    this.compact = false,
  });

  final int value;
  final int target;
  final Color accent;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              value: value,
              target: target,
              accent: accent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                compact
                    ? '${((value / target) * 100).round()}%'
                    : value.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]},'),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: compact ? size * 0.26 : size * 0.18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -1.2,
                ),
              ),
              if (!compact)
                Text(
                  'of ${target.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} kcal',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: size * 0.054,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkWithOpacity(0.55),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.value,
    required this.target,
    required this.accent,
  });

  final int value;
  final int target;
  final Color accent;

  // Arc spans 220° — from -200° to +20° (open at bottom-right)
  static const double _startDeg = -200;
  static const double _endDeg = 20;
  static const double _span = _endDeg - _startDeg; // 220°

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;
    final strokeW = size.width * 0.13;

    double degToRad(double deg) => (deg - 90) * pi / 180;

    final pct = (value / target).clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    canvas.drawArc(rect, degToRad(_startDeg), _span * pi / 180, false, trackPaint);

    if (pct > 0.001) {
      canvas.drawArc(
        rect,
        degToRad(_startDeg),
        (_span * pct) * pi / 180,
        false,
        fillPaint,
      );
    }

  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.target != target || old.accent != accent;
}
