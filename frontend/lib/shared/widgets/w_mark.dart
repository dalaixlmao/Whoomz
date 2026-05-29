import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// The W logo mark — drawn as four diagonal strokes meeting at three apexes.
/// SVG path on 40×40 viewBox: M3 10 L13 32 L20 19 L27 32 L37 10
class WMark extends StatelessWidget {
  const WMark({
    super.key,
    this.size = 32,
    this.color = AppColors.ink,
    this.bgColor,
  });

  final double size;
  final Color color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    final bg = bgColor;
    return Container(
      width: size,
      height: size,
      decoration: bg != null
          ? BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.28))
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _WMarkPainter(color: color),
      ),
    );
  }
}

class _WMarkPainter extends CustomPainter {
  const _WMarkPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.4 * 4.5 / 40
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 40;
    final scaleY = size.height / 40;
    final path = Path()
      ..moveTo(3 * scaleX, 10 * scaleY)
      ..lineTo(13 * scaleX, 32 * scaleY)
      ..lineTo(20 * scaleX, 19 * scaleY)
      ..lineTo(27 * scaleX, 32 * scaleY)
      ..lineTo(37 * scaleX, 10 * scaleY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WMarkPainter old) => old.color != color;
}
