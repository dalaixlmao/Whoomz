import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers.dart';

class ChatMessage {
  const ChatMessage({required this.role, required this.text, this.nutrition});
  final String role; // 'user' | 'ai' | 'done'
  final String text;
  final NutritionData? nutrition;
}

class NutritionData {
  const NutritionData({required this.kcal, required this.p, required this.c, required this.f});
  final int kcal;
  final int p;
  final int c;
  final int f;
}

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.sessionId = '',
  });

  final List<ChatMessage> messages;
  final bool isTyping;
  final String sessionId;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? sessionId,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        sessionId: sessionId ?? this.sessionId,
      );
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState(
      sessionId: const Uuid().v4(),
      messages: const [
        ChatMessage(role: 'ai', text: "Morning! How's your energy today? ☕"),
      ],
    );
  }

  Future<void> send(String text) async {
    final userMsg = ChatMessage(role: 'user', text: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    final buffer = StringBuffer();
    try {
      final repo = ref.read(chatRepositoryProvider);
      final stream = repo.chat(sessionId: state.sessionId, message: text);

      await for (final chunk in stream) {
        buffer.write(chunk);
      }

      final raw = buffer.toString().trim();
      final nutrition = _parseNutrition(raw);
      final clean = raw.replaceAll(RegExp(r'__NUTRITION__\{[^}]+\}'), '').trim();

      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'ai', text: clean, nutrition: nutrition)],
        isTyping: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          const ChatMessage(role: 'ai', text: "I'm offline for a sec — but I'm here. Tell me again?"),
        ],
        isTyping: false,
      );
    }
  }

  void markDone() {
    state = state.copyWith(
      messages: [...state.messages, const ChatMessage(role: 'done', text: '')],
    );
  }

  void reset(String greeting) {
    state = ChatState(
      sessionId: const Uuid().v4(),
      messages: [ChatMessage(role: 'ai', text: greeting)],
    );
  }

  NutritionData? _parseNutrition(String raw) {
    final m = RegExp(r'__NUTRITION__\{"kcal":(\d+),"p":(\d+),"c":(\d+),"f":(\d+)\}').firstMatch(raw);
    if (m == null) return null;
    return NutritionData(
      kcal: int.parse(m.group(1)!),
      p: int.parse(m.group(2)!),
      c: int.parse(m.group(3)!),
      f: int.parse(m.group(4)!),
    );
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
