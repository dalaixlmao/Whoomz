import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/blinking_caret.dart';
import '../../../shared/widgets/composer.dart';
import '../../food_logs/presentation/meals_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../tweaks/tweaks_controller.dart';
import '../../tweaks/tweaks_screen.dart';
import '../../voice/presentation/voice_screen.dart';
import '../../workouts/presentation/workout_screens.dart';
import 'conversation_controller.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, this.autofocus = false});

  final bool autofocus;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    _input.clear();
    // The conversation is the navigation.
    final destination = switch (text.toLowerCase()) {
      'progress' => const ProgressScreen() as Widget,
      'meals' => const MealsScreen(),
      'workouts' => const WorkoutsScreen(),
      'tweaks' => const TweaksScreen(),
      _ => null,
    };
    if (destination != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => destination));
      return;
    }
    ref.read(conversationProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    final state = ref.watch(conversationProvider);
    final entries = state.entries.reversed.toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '‹ TODAY',
                      style: WhoomzType.caps.copyWith(color: wz.whisper),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'Say anything — food, weight,\nworkouts, doubts.',
                        textAlign: TextAlign.center,
                        style: WhoomzType.body.copyWith(color: wz.whisper),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (_, i) => _EntryView(
                        entry: entries[i],
                        bubbleStyle: ref.watch(tweaksProvider).bubbleStyle,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Composer(
                hint: 'Say anything',
                controller: _input,
                autofocus: widget.autofocus,
                onSubmitted: _submit,
                onVoice: () => Navigator.of(
                  context,
                ).push(fadeUpRoute(const VoiceScreen())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryView extends StatelessWidget {
  const _EntryView({required this.entry, this.bubbleStyle = BubbleStyle.ink});

  final Entry entry;
  final BubbleStyle bubbleStyle;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: switch (entry) {
        UserEntry(:final text) => Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleStyle == BubbleStyle.ink ? wz.ink : null,
              border: bubbleStyle == BubbleStyle.outline
                  ? Border.all(color: wz.hairline, width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              text,
              style: WhoomzType.body.copyWith(
                color: bubbleStyle == BubbleStyle.ink ? wz.onInk : wz.ink,
              ),
            ),
          ),
        ),
        CoachEntry() => _CoachText(entry: entry as CoachEntry),
        ActionEntry(:final label) => Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: wz.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: WhoomzType.caps.copyWith(color: wz.whisper),
              ),
            ),
          ],
        ),
      },
    );
  }
}

/// Coach replies are plain text on paper — no bubble, no avatar. Settled
/// sentences in ink; the in-flight tail whispers until it lands.
class _CoachText extends StatelessWidget {
  const _CoachText({required this.entry});

  final CoachEntry entry;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    if (entry.isEmpty && entry.streaming) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: BlinkingCaret(),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: entry.committed,
                style: WhoomzType.body.copyWith(color: wz.ink),
              ),
              if (entry.pending.isNotEmpty)
                TextSpan(
                  text: '${entry.committed.isEmpty ? '' : ' '}${entry.pending}',
                  style: WhoomzType.body.copyWith(color: wz.whisper),
                ),
              if (entry.streaming)
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: BlinkingCaret(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
