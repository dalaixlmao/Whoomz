import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ChatRepository {
  Stream<String> chat({
    required String sessionId,
    required String message,
    String mode = 'text',
  }) async* {
    final response = await ApiClient.dio.post<ResponseBody>(
      '/chat/',
      data: {'session_id': sessionId, 'message': message, 'mode': mode},
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream
        .map((chunk) => utf8.decode(chunk))
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (line.startsWith('data: ')) {
        final payload = line.substring(6);
        if (payload == '[DONE]') break;
        yield payload;
      }
    }
  }
}
