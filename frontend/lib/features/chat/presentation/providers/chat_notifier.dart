import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers.dart';
import '../../../food_logs/data/food_log_models.dart';
import '../../../workouts/data/workout_models.dart';

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
      messages: [...state.messages, userMsg, const ChatMessage(role: 'ai', text: '')],
      isTyping: false,
    );

    final buffer = StringBuffer();
    try {
      final repo = ref.read(chatRepositoryProvider);
      final stream = repo.chat(sessionId: state.sessionId, message: text);

      await for (final chunk in stream) {
        final json = jsonDecode(chunk) as Map<String, dynamic>;
        if (json['done'] == true) break;

        final action = json['action'] as String?;
        if (action != null) {
          _handleAction(action, json['data'] as Map<String, dynamic>?);
          continue;
        }

        buffer.write((json['text'] as String?) ?? '');
        final updated = List<ChatMessage>.from(state.messages);
        updated[updated.length - 1] = ChatMessage(role: 'ai', text: buffer.toString());
        state = state.copyWith(messages: updated);
      }

      final raw = buffer.toString().trim();
      final nutrition = _parseNutrition(raw);
      final clean = raw.replaceAll(RegExp(r'__NUTRITION__\{[^}]+\}'), '').trim();
      final finalized = List<ChatMessage>.from(state.messages);
      finalized[finalized.length - 1] = ChatMessage(role: 'ai', text: clean, nutrition: nutrition);
      state = state.copyWith(messages: finalized);
    } catch (_) {
      final msgs = List<ChatMessage>.from(state.messages);
      msgs[msgs.length - 1] = const ChatMessage(role: 'ai', text: "I'm offline for a sec — but I'm here. Tell me again?");
      state = state.copyWith(messages: msgs, isTyping: false);
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

  void _handleAction(String action, Map<String, dynamic>? data) {
    switch (action) {
      case 'food_logged':
        if (data != null) {
          ref.read(foodLogNotifierProvider.notifier).addItem(FoodLogResponse.fromJson(data));
        }
      case 'workout_logged':
        if (data != null) {
          ref.read(workoutNotifierProvider.notifier).addItem(WorkoutDetailResponse.fromJson(data));
        }
      case 'log_failed':
        final msgs = List<ChatMessage>.from(state.messages);
        msgs.insert(
          msgs.length - 1,
          const ChatMessage(role: 'error', text: "Couldn't save to your log."),
        );
        state = state.copyWith(messages: msgs);
    }
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
