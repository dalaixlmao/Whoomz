import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'voice_glyph.dart';

/// The floating input pill — primary action, bottom 30% of every screen.
class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.hint,
    this.controller,
    this.onSubmitted,
    this.onVoice,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVoice;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 60,
        padding: const EdgeInsets.only(left: 24, right: 8),
        decoration: BoxDecoration(
          color: wz.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: WhoomzPalette.light.ink.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                readOnly: readOnly,
                onTap: onTap,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.send,
                style: WhoomzType.body.copyWith(color: wz.ink),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: WhoomzType.body.copyWith(color: wz.faint),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            if (onVoice != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onVoice,
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: Hero(tag: 'voice-orb', child: VoiceGlyph()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
