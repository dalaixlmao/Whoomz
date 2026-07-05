import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../domain/chat_events.dart';

class ChatRepository {
  ChatRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// One endpoint for both input modes — same session, same history.
  Stream<ChatEvent> send({
    required String sessionId,
    required String message,
    String mode = 'text',
  }) async* {
    final response = await _dio.post<ResponseBody>(
      ApiEndpoints.chat,
      data: {'session_id': sessionId, 'message': message, 'mode': mode},
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    final lines = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring(6).trim();
      if (payload == '[DONE]') {
        yield const ChatDone();
        break;
      }
      final event = _decode(payload);
      if (event == null) continue;
      yield event;
      if (event is ChatDone) break;
    }
  }

  ChatEvent? _decode(String payload) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(payload) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
    if (json['done'] == true) return const ChatDone();
    final text = json['text'];
    if (text is String) return ChatText(text);
    final action = json['action'];
    if (action is String) {
      return ChatAction(action, json['data'] as Map<String, dynamic>?);
    }
    final error = json['error'];
    if (error is String) return ChatFailure(error);
    return null;
  }
}
