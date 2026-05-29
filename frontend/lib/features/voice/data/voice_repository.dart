import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class VoiceRepository {
  Stream<String> voiceChat({
    required String sessionId,
    required String transcript,
  }) async* {
    final response = await ApiClient.dio.post<ResponseBody>(
      '/voice/chat',
      data: {'session_id': sessionId, 'transcript': transcript},
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
