import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// No grid, no axes: the line, the dots, one accent point at the end.
class TrendLine extends StatelessWidget {
  const TrendLine({
    super.key,
    required this.values,
    this.height = 120,
    this.showDots = true,
  });

  final List<double> values;
  final double height;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(
          values: values,
          ink: wz.ink,
          accent: wz.accent,
          showDots: showDots,
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.ink,
    required this.accent,
    required this.showDots,
  });

  final List<double> values;
  final Color ink;
  final Color accent;
  final bool showDots;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      if (values.length == 1) {
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          4,
          Paint()..color = accent,
        );
      }
      return;
    }

    const inset = 6.0;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min) == 0 ? 1.0 : (max - min);

    Offset point(int i) {
      final x = inset + (size.width - 2 * inset) * i / (values.length - 1);
      final t = (values[i] - min) / span;
      final y = inset + (size.height - 2 * inset) * (1 - t);
      return Offset(x, y);
    }

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = ink.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (showDots) {
      final dot = Paint()..color = ink;
      for (var i = 0; i < values.length - 1; i++) {
        canvas.drawCircle(point(i), 3, dot);
      }
    }
    canvas.drawCircle(point(values.length - 1), 4.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values ||
      old.ink != ink ||
      old.accent != accent ||
      old.showDots != showDots;
}
