/// SSE events from POST /api/v1/chat:
///   data: {"text": "…"}
///   data: {"action": "food_logged"|"workout_logged"|"log_failed", "data": {...}}
///   data: {"error": "..."}
///   data: {"done": true}
sealed class ChatEvent {
  const ChatEvent();
}

class ChatText extends ChatEvent {
  final String text;
  const ChatText(this.text);
}

class ChatAction extends ChatEvent {
  final String action;
  final Map<String, dynamic>? data;
  const ChatAction(this.action, this.data);
}

class ChatFailure extends ChatEvent {
  final String message;
  const ChatFailure(this.message);
}

class ChatDone extends ChatEvent {
  const ChatDone();
}
