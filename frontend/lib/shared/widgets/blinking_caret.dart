import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The streaming caret — one of the three places the accent is allowed.
class BlinkingCaret extends StatefulWidget {
  const BlinkingCaret({super.key, this.height = 18});

  final double height;

  @override
  State<BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 530),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2.5,
        height: widget.height,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          color: WhoomzPalette.accent,
          borderRadius: BorderRadius.circular(1.25),
        ),
      ),
    );
  }
}
