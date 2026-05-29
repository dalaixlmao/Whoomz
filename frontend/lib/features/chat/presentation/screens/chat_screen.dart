import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/w_mark.dart';
import '../../../../shared/widgets/chat_bubble.dart';
import '../../../../shared/widgets/typing_indicator.dart';
import '../../../../shared/widgets/quick_chip.dart';
import '../../../../shared/widgets/voice_mic_button.dart';
import '../../../../shared/widgets/nutrition_stamp.dart';
import '../../../../shared/widgets/w_stamp.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/chat_notifier.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _recording = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    ref.read(chatNotifierProvider.notifier).send(text.trim());
    _scrollToBottom();
  }

  void _done() {
    ref.read(chatNotifierProvider.notifier).markDone();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/app/summary');
    });
  }

  static const _indianChips = [
    ('Chai', '☕'), ('Roti', '🫓'), ('Dal', '🥗'), ('Rice', '🍚'),
    ('Eggs', '🍳'), ('Sabzi', '🥬'), ('Samosa', '🥟'),
  ];

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final userName = ref.watch(authNotifierProvider).user?.name ?? 'you';

    ref.listen(chatNotifierProvider, (_, _) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(userName, chatState.isTyping),
            Expanded(child: _buildMessages(chatState)),
            _buildChips(),
            _buildInputRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, bool isTyping) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.inkWithOpacity(0.08))),
      ),
      child: Row(
        children: [
          const WMark(size: 36, color: AppColors.accent, bgColor: Color(0x1A5C2D91)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Whoomz', style: GoogleFonts.bricolageGrotesque(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.2)),
                    const SizedBox(width: 6),
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                  ],
                ),
                Text(
                  isTyping ? 'typing…' : 'here for you, $name',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 12, color: AppColors.inkWithOpacity(0.4), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _done,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.accentWithOpacity(0.4), width: 1.5),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            ),
            child: Text('End ✓', style: GoogleFonts.bricolageGrotesque(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(ChatState state) {
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      itemCount: state.messages.length + (state.isTyping ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == state.messages.length) {
          return const TypingIndicator();
        }
        final msg = state.messages[i];
        if (msg.role == 'user') return UserBubble(text: msg.text);
        if (msg.role == 'done') {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const WStamp(size: 84, color: AppColors.accent, rotateDegrees: -6, label: 'DONE FOR TODAY'),
                const SizedBox(height: 8),
                Text(
                  'Whoomz · ${_todayLabel()}',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.accent),
                ),
              ],
            ),
          );
        }
        return AIBubble(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg.text, style: chatTextStyle()),
              if (msg.nutrition != null)
                NutritionStamp(
                  kcal: msg.nutrition!.kcal,
                  proteinG: msg.nutrition!.p,
                  carbsG: msg.nutrition!.c,
                  fatG: msg.nutrition!.f,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        children: _indianChips.map((c) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: QuickChip(
            label: c.$1,
            emoji: c.$2,
            variant: ChipVariant.outline,
            size: ChipSize.sm,
            onTap: () => _send('Had some ${c.$1.toLowerCase()} ${c.$2}'),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bubbleAI,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.inkWithOpacity(0.15), width: 1.5),
              ),
              child: TextField(
                controller: _ctrl,
                onSubmitted: _send,
                style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.ink, letterSpacing: -0.05),
                decoration: InputDecoration(
                  hintText: 'Tell me about your day…',
                  hintStyle: GoogleFonts.dmSans(color: AppColors.inkWithOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          VoiceMicButton(
            recording: _recording,
            onTap: () => setState(() => _recording = !_recording),
            size: 48,
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day}';
  }
}
