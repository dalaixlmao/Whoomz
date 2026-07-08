import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/auth/token_storage.dart';
import '../../core/providers.dart';
import '../auth/presentation/auth_controller.dart';
import 'tweaks_controller.dart';

/// 2g — the settings the board promised: each choice is a single line you
/// tap to cycle. No sections, no toggles.
class TweaksScreen extends ConsumerStatefulWidget {
  const TweaksScreen({super.key});

  @override
  ConsumerState<TweaksScreen> createState() => _TweaksScreenState();
}

class _TweaksScreenState extends ConsumerState<TweaksScreen> {
  late bool _remembered = !TokenStorage.sessionOnly;

  Future<void> _toggleRemember() async {
    final next = !_remembered;
    setState(() => _remembered = next);
    await ref.read(tokenStorageProvider).setRememberMe(next);
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    final tweaks = ref.watch(tweaksProvider);
    final controller = ref.read(tweaksProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Text(
                      '‹ TODAY',
                      style: WhoomzType.caps.copyWith(color: wz.whisper),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Tweaks', style: WhoomzType.metric.copyWith(color: wz.ink)),
              const SizedBox(height: 40),
              _TweakLine(
                label: 'ACCENT',
                value: tweaks.accent.name,
                trailing: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tweaks.accent.color,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: controller.cycleAccent,
              ),
              _TweakLine(
                label: 'ORB',
                value: tweaks.orbStyle.name.toUpperCase(),
                onTap: controller.cycleOrb,
              ),
              _TweakLine(
                label: 'BUBBLE',
                value: tweaks.bubbleStyle.name.toUpperCase(),
                onTap: controller.cycleBubble,
              ),
              _TweakLine(
                label: 'REMEMBER ME',
                value: _remembered ? 'ON' : 'OFF',
                onTap: _toggleRemember,
              ),
              const Spacer(),
              _TweakLine(label: 'SIGN OUT', value: '', onTap: _signOut),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TweakLine extends StatelessWidget {
  const _TweakLine({
    required this.label,
    required this.value,
    this.trailing,
    required this.onTap,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Text(label, style: WhoomzType.caps.copyWith(color: wz.whisper)),
            const Spacer(),
            Text(value, style: WhoomzType.caps.copyWith(color: wz.ink)),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}
