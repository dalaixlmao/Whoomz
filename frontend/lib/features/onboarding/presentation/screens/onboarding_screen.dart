import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/w_mark.dart';
import '../../../../shared/widgets/chat_bubble.dart';
import '../../../../shared/widgets/quick_chip.dart';
import '../../../../shared/widgets/voice_mic_button.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _picked;
  String _name = '';
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  static const _goals = [
    ('More energy', '⚡', 'energy'),
    ('Lose some weight', '🎯', 'weight'),
    ('Eat better', '🥗', 'eat'),
  ];

  static const _modes = [
    ('Voice mostly', '🎙️', 'voice'),
    ('Text mostly', '💬', 'text'),
    ("I'll mix it", '✨', 'both'),
  ];

  String get _aiText => switch (_step) {
        0 => "Hey! 👋 What's one thing you want to feel better about — energy, weight, or eating cleaner?",
        1 => switch (_picked) {
            'energy' => "Love that. Energy comes from sleep, food, and rhythm — we'll build it together. What should I call you?",
            'weight' => "Got it. We'll track it like a journal, not a courtroom. What should I call you?",
            _ => "Nice. We'll keep it loose — log what you actually eat, not what you're supposed to. What should I call you?",
          },
        2 => "Perfect, $_name. One last thing — voice or text? Most folks just talk.",
        _ => '',
      };

  void _advance() {
    if (_step < 2) setState(() => _step++);
  }

  Future<void> _finish(String mode) async {
    final name = _name.isNotEmpty ? _name : 'You';
    await ref.read(authNotifierProvider.notifier).completeOnboarding(name);
    if (mounted) context.go('/app/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentWithOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: WMark(size: 32, color: AppColors.accent)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Whoomz', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.2)),
                      Text(_step == 2 ? '' : 'typing…', style: GoogleFonts.bricolageGrotesque(fontSize: 11, color: AppColors.inkWithOpacity(0.4), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),

            // Chat messages
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // History
                  for (int i = 0; i < _step; i++) ...[
                    AIBubble(child: Text(_aiTextForStep(i), style: chatTextStyle())),
                    const SizedBox(height: 12),
                    if (i == 0 && _picked != null)
                      UserBubble(
                        text: '${_goals.firstWhere((g) => g.$3 == _picked).$2} ${_goals.firstWhere((g) => g.$3 == _picked).$1}',
                      ),
                    if (i == 1)
                      UserBubble(text: _name),
                    const SizedBox(height: 12),
                  ],
                  // Current AI
                  AIBubble(
                    key: ValueKey('ai-$_step'),
                    child: Text(_aiText, style: chatTextStyle()),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Footer: chips or input
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  String _aiTextForStep(int i) => switch (i) {
        0 => "Hey! 👋 What's one thing you want to feel better about — energy, weight, or eating cleaner?",
        1 => switch (_picked) {
            'energy' => "Love that. Energy comes from sleep, food, and rhythm — we'll build it together. What should I call you?",
            'weight' => "Got it. We'll track it like a journal, not a courtroom. What should I call you?",
            _ => "Nice. We'll keep it loose — log what you actually eat, not what you're supposed to. What should I call you?",
          },
        2 => "Perfect, $_name. One last thing — voice or text? Most folks just talk.",
        _ => '',
      };

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      color: AppColors.cream,
      child: switch (_step) {
        0 => _chipRow(_goals.map((g) => (g.$1, g.$2, g.$3)).toList(), (val) {
            setState(() { _picked = val; });
            Future.delayed(const Duration(milliseconds: 350), _advance);
          }),
        1 => _nameInput(),
        2 => Column(
            children: [
              _chipRow(_modes.map((m) => (m.$1, m.$2, m.$3)).toList(), (val) => _finish(val)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: VoiceMicButton(recording: false, onTap: () {}, size: 52),
              ),
            ],
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _chipRow(List<(String, String, String)> chips, void Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) => QuickChip(
        label: c.$1,
        emoji: c.$2,
        variant: _picked == c.$3 ? ChipVariant.filled : ChipVariant.soft,
        onTap: () => onSelect(c.$3),
      )).toList(),
    );
  }

  Widget _nameInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.accentWithOpacity(0.3), width: 1.5),
            ),
            child: TextField(
              controller: _nameCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _name = v),
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Type your name…',
                hintStyle: GoogleFonts.dmSans(color: AppColors.inkWithOpacity(0.35)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (_nameCtrl.text.trim().isNotEmpty) {
              setState(() => _name = _nameCtrl.text.trim());
              _advance();
            }
          },
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.accentWithOpacity(0.55), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
