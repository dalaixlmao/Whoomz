import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../conversation/presentation/conversation_controller.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../tweaks/tweaks_controller.dart';
import '../voice_engine.dart';
import 'orb.dart';

enum _Phase { starting, listening, thinking, speaking, unavailable }

/// 1d — the orb breathes with your voice · tap anywhere for text.
/// In dark mode this is 1g: true black, same restraint.
class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final VoiceEngine _engine = VoiceEngine();
  final List<String> _queue = [];

  _Phase _phase = _Phase.starting;
  double _micLevel = 0;
  double _pulse = 0;
  String _heard = '';
  bool _draining = false;
  bool _closing = false;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final ready = await _engine.init();
    if (!mounted) return;
    if (!ready) {
      setState(() => _phase = _Phase.unavailable);
      return;
    }
    _listen();
  }

  Future<void> _listen() async {
    if (_closing || !mounted) return;
    setState(() {
      _phase = _Phase.listening;
      _heard = '';
      _micLevel = 0;
    });
    await _engine.listen(
      onResult: (words, isFinal) {
        if (!mounted || _phase != _Phase.listening) return;
        setState(() => _heard = words);
        if (isFinal) _handleFinal(words);
      },
      onLevel: (level) {
        if (mounted && _phase == _Phase.listening) {
          setState(() => _micLevel = level);
        }
      },
    );
  }

  Future<void> _handleFinal(String words) async {
    final text = words.trim();
    await _engine.stopListening();
    if (!mounted || _closing) return;
    if (text.isEmpty) {
      _listen();
      return;
    }
    if (text.toLowerCase().replaceAll(RegExp(r'[.!?]'), '') == 'progress') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProgressScreen()),
      );
      return;
    }
    setState(() {
      _phase = _Phase.thinking;
      _micLevel = 0;
    });
    await ref
        .read(conversationProvider.notifier)
        .send(text, mode: 'voice', onSentence: _enqueue);
    while (_draining && !_closing) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (mounted && !_closing) _listen();
  }

  void _enqueue(String sentence) {
    _queue.add(sentence);
    if (!_draining) _drain();
  }

  Future<void> _drain() async {
    _draining = true;
    _startPulse();
    if (mounted && !_closing) setState(() => _phase = _Phase.speaking);
    while (_queue.isNotEmpty && !_closing) {
      await _engine.speak(_queue.removeAt(0));
    }
    _stopPulse();
    _draining = false;
  }

  void _startPulse() {
    _pulseTimer ??= Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) return;
      setState(() {
        _pulse = 0.35 + 0.3 * (0.5 + 0.5 * math.sin(t.tick * 0.45));
      });
    });
  }

  void _stopPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
    if (mounted && !_closing) setState(() => _pulse = 0);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _queue.clear();
    _pulseTimer?.cancel();
    await _engine.dispose();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _closing = true;
    _pulseTimer?.cancel();
    _engine.dispose();
    super.dispose();
  }

  String get _statusLabel => switch (_phase) {
    _Phase.starting => 'ONE MOMENT',
    _Phase.listening => 'LISTENING',
    _Phase.thinking => 'THINKING',
    _Phase.speaking => 'SPEAKING',
    _Phase.unavailable => 'MIC UNAVAILABLE',
  };

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    final level = switch (_phase) {
      _Phase.listening => _micLevel,
      _Phase.speaking => _pulse,
      _ => 0.0,
    };

    final coach = ref
        .watch(conversationProvider)
        .entries
        .whereType<CoachEntry>()
        .lastOrNull;
    final centerText = switch (_phase) {
      _Phase.listening => _heard,
      _Phase.thinking || _Phase.speaking =>
        coach == null ? '' : '${coach.committed} ${coach.pending}'.trim(),
      _Phase.unavailable => 'Tap anywhere to type instead.',
      _Phase.starting => '',
    };

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 72),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_phase == _Phase.listening) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: wz.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _statusLabel,
                    style: WhoomzType.caps.copyWith(color: wz.whisper),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      centerText,
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: WhoomzType.body.copyWith(
                        fontSize: 22,
                        color: _phase == _Phase.listening ? wz.ink : wz.whisper,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: Hero(
                  tag: 'voice-orb',
                  child: Orb(
                    level: level,
                    style: ref.watch(tweaksProvider).orbStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
