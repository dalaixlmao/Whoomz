import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/units.dart';
import '../../today/presentation/today_providers.dart';
import '../domain/chat_events.dart';
import '../domain/sentence_buffer.dart';

sealed class Entry {
  const Entry(this.id);
  final int id;
}

class UserEntry extends Entry {
  const UserEntry(super.id, this.text);
  final String text;
}

class CoachEntry extends Entry {
  const CoachEntry(
    super.id, {
    this.committed = '',
    this.pending = '',
    this.streaming = true,
  });

  /// Settled sentences render in ink; the in-flight tail stays whisper-gray
  /// behind the blinking caret.
  final String committed;
  final String pending;
  final bool streaming;

  bool get isEmpty => committed.isEmpty && pending.isEmpty;

  CoachEntry copyWith({String? committed, String? pending, bool? streaming}) =>
      CoachEntry(
        id,
        committed: committed ?? this.committed,
        pending: pending ?? this.pending,
        streaming: streaming ?? this.streaming,
      );
}

/// "LOGGED · CHICKEN BOWL · 610 KCAL" — a quiet receipt in the transcript.
class ActionEntry extends Entry {
  const ActionEntry(super.id, this.label);
  final String label;
}

class ConversationState {
  const ConversationState({this.entries = const [], this.busy = false});

  final List<Entry> entries;
  final bool busy;

  ConversationState copyWith({List<Entry>? entries, bool? busy}) =>
      ConversationState(
        entries: entries ?? this.entries,
        busy: busy ?? this.busy,
      );
}

final conversationProvider =
    NotifierProvider<ConversationController, ConversationState>(
      ConversationController.new,
    );

class ConversationController extends Notifier<ConversationState> {
  final String sessionId = const Uuid().v4();
  int _nextId = 0;

  @override
  ConversationState build() => const ConversationState();

  Future<void> send(
    String message, {
    String mode = 'text',
    void Function(String sentence)? onSentence,
  }) async {
    if (state.busy) return;
    final coachId = _nextId + 1;
    state = state.copyWith(
      entries: [
        ...state.entries,
        UserEntry(_nextId, message),
        CoachEntry(coachId),
      ],
      busy: true,
    );
    _nextId += 2;

    final sentences = SentenceBuffer();
    try {
      final stream = ref
          .read(chatRepositoryProvider)
          .send(sessionId: sessionId, message: message, mode: mode);
      await for (final event in stream) {
        switch (event) {
          case ChatText(:final text):
            for (final sentence in sentences.add(text)) {
              _commitSentence(coachId, sentence);
              onSentence?.call(sentence);
            }
            _updateCoach(
              coachId,
              (c) => c.copyWith(pending: sentences.pending),
            );
          case ChatAction(:final action, :final data):
            _appendAction(action, data);
          case ChatFailure(:final message):
            _commitSentence(coachId, message);
            onSentence?.call(message);
          case ChatDone():
            break;
        }
      }
    } on DioException {
      _commitSentence(
        coachId,
        "Can't reach your coach right now — check the connection.",
      );
    } finally {
      final rest = sentences.flush();
      if (rest.isNotEmpty) {
        _commitSentence(coachId, rest);
        onSentence?.call(rest);
      }
      _updateCoach(coachId, (c) => c.copyWith(pending: '', streaming: false));
      state = state.copyWith(busy: false);
    }
  }

  void _commitSentence(int coachId, String sentence) {
    _updateCoach(coachId, (c) {
      final joined = c.committed.isEmpty
          ? sentence
          : '${c.committed} $sentence';
      return c.copyWith(committed: joined);
    });
  }

  void _updateCoach(int coachId, CoachEntry Function(CoachEntry) transform) {
    state = state.copyWith(
      entries: [
        for (final e in state.entries)
          if (e is CoachEntry && e.id == coachId) transform(e) else e,
      ],
    );
  }

  void _appendAction(String action, Map<String, dynamic>? data) {
    final label = switch (action) {
      'food_logged' => _foodLabel('LOGGED', data),
      'food_removed' => _foodLabel('REMOVED', data),
      'workout_logged' =>
        'LOGGED · ${(data?['name'] as String? ?? 'WORKOUT').toUpperCase()}',
      'log_failed' => "COULDN'T SAVE THAT ONE",
      _ => null,
    };
    if (label == null) return;
    state = state.copyWith(
      entries: [...state.entries, ActionEntry(_nextId++, label)],
    );
    if (action != 'log_failed') {
      ref.invalidate(todayProvider);
      ref.invalidate(streakProvider);
    }
  }

  String _foodLabel(String verb, Map<String, dynamic>? data) {
    final name = (data?['name'] as String? ?? 'FOOD').toUpperCase();
    final kcal = data?['calories'];
    return kcal is num
        ? '$verb · $name · ${formatKcal(kcal)} KCAL'
        : '$verb · $name';
  }
}
