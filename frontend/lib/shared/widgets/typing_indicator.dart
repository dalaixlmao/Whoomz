import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'chat_bubble.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.accent = AppColors.accent,
    this.bgColor = AppColors.bubbleAI,
  });

  final Color accent;
  final Color bgColor;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AIBubble(
      accent: widget.accent,
      bgColor: widget.bgColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final delay = i * 0.16;
              final t = (_controller.value - delay).clamp(0.0, 1.0);
              final bounce = (t < 0.5 ? t : 1 - t) * 2;
              return Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                transform: Matrix4.translationValues(0, -4 * bounce, 0),
              );
            },
          );
        }),
      ),
    );
  }
}
