import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'w_mark.dart';

/// Shared text style for chat content — always DM Sans, never swapped.
TextStyle chatTextStyle({Color color = AppColors.ink}) => GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.38,
      letterSpacing: -0.05,
    );

class UserBubble extends StatelessWidget {
  const UserBubble({
    super.key,
    required this.text,
    this.accent = AppColors.accent,
  });

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(text, style: chatTextStyle(color: Colors.white)),
      ),
    );
  }
}

class AIBubble extends StatelessWidget {
  const AIBubble({
    super.key,
    required this.child,
    this.accent = AppColors.accent,
    this.bgColor = AppColors.bubbleAI,
    this.textColor = AppColors.ink,
    this.showAvatar = true,
  });

  final Widget child;
  final Color accent;
  final Color bgColor;
  final Color textColor;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAvatar)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Center(child: WMark(size: 20, color: accent)),
            )
          else
            const SizedBox(width: 36),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
