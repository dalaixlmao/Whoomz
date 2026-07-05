import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The five-bar waveform — the only pictogram in the app, always accent.
class VoiceGlyph extends StatelessWidget {
  const VoiceGlyph({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

class _WavePainter extends CustomPainter {
  static const _heights = [0.35, 0.7, 1.0, 0.55, 0.3];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WhoomzPalette.accent
      ..strokeWidth = size.width / 8
      ..strokeCap = StrokeCap.round;
    final step = size.width / (_heights.length - 1);
    for (var i = 0; i < _heights.length; i++) {
      final x = i * step;
      final half = size.height * _heights[i] / 2;
      final mid = size.height / 2;
      canvas.drawLine(Offset(x, mid - half), Offset(x, mid + half), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}
