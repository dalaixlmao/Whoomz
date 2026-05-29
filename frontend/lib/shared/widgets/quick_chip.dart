import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum ChipVariant { outline, filled, soft }

class QuickChip extends StatefulWidget {
  const QuickChip({
    super.key,
    required this.label,
    this.emoji,
    this.variant = ChipVariant.outline,
    this.accent = AppColors.accent,
    this.bgColor = AppColors.bubbleAI,
    this.textColor = AppColors.ink,
    this.size = ChipSize.md,
    this.onTap,
  });

  final String label;
  final String? emoji;
  final ChipVariant variant;
  final Color accent;
  final Color bgColor;
  final Color textColor;
  final ChipSize size;
  final VoidCallback? onTap;

  @override
  State<QuickChip> createState() => _QuickChipState();
}

enum ChipSize { sm, md }

class _QuickChipState extends State<QuickChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSmall = widget.size == ChipSize.sm;
    final hPad = isSmall ? 12.0 : 16.0;
    final vPad = isSmall ? 7.0 : 10.0;
    final fs = isSmall ? 13.0 : 14.5;

    Color bg;
    Color border;
    Color text;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case ChipVariant.filled:
        bg = widget.accent;
        border = widget.accent;
        text = Colors.white;
        shadows = [BoxShadow(color: widget.accent.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))];
      case ChipVariant.soft:
        bg = widget.accent.withValues(alpha: 0.12);
        border = widget.accent.withValues(alpha: 0.25);
        text = widget.accent;
      case ChipVariant.outline:
        bg = widget.bgColor;
        border = widget.accent.withValues(alpha: 0.3);
        text = widget.textColor;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(999),
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: fs,
                  fontWeight: FontWeight.w600,
                  color: text,
                  letterSpacing: -0.1,
                ),
              ),
              if (widget.emoji != null) ...[
                const SizedBox(width: 6),
                Text(widget.emoji!, style: TextStyle(fontSize: fs + 1)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
