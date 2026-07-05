import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme.dart';

/// The orb breathes with your voice — idle it sighs, speaking it pulses.
class Orb extends StatefulWidget {
  const Orb({super.key, required this.level, this.diameter = 120});

  /// 0..1 — mic amplitude while listening, synthetic pulse while speaking.
  final double level;
  final double diameter;

  @override
  State<Orb> createState() => _OrbState();
}

class _OrbState extends State<Orb> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _shown = 0;
  double _idlePhase = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _idlePhase = elapsed.inMilliseconds / 1000;
        // Spring-like settle toward the live level.
        _shown += (widget.level - _shown) * 0.12;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breath = 0.03 * math.sin(_idlePhase * 2 * math.pi / 3.2);
    final scale = 1 + breath + _shown * 0.28;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: WhoomzPalette.accent,
          boxShadow: [
            BoxShadow(
              color: WhoomzPalette.accent.withValues(alpha: 0.35),
              blurRadius: 48,
              spreadRadius: 8 + _shown * 12,
            ),
          ],
        ),
      ),
    );
  }
}
