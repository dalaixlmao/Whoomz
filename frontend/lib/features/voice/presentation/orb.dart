import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme.dart';
import '../../tweaks/tweaks_controller.dart';

/// The orb breathes with your voice — idle it sighs, speaking it pulses.
/// Style (filled / ring) comes from Tweaks; color is the theme accent.
class Orb extends StatefulWidget {
  const Orb({
    super.key,
    required this.level,
    this.style = OrbStyle.filled,
    this.diameter = 120,
  });

  /// 0..1 — mic amplitude while listening, synthetic pulse while speaking.
  final double level;
  final OrbStyle style;
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
    final accent = context.wz.accent;
    final breath = 0.03 * math.sin(_idlePhase * 2 * math.pi / 3.2);
    final scale = 1 + breath + _shown * 0.28;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.style == OrbStyle.filled ? accent : null,
          border: widget.style == OrbStyle.ring
              ? Border.all(color: accent, width: 10)
              : null,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 48,
              spreadRadius: 8 + _shown * 12,
            ),
          ],
        ),
      ),
    );
  }
}
