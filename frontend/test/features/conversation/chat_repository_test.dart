import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whoomz/features/conversation/data/chat_repository.dart';
import 'package:whoomz/features/conversation/domain/chat_events.dart';

class _MockDio extends Mock implements Dio {}

ResponseBody _sse(List<String> lines) {
  final bytes = utf8.encode(lines.join());
  return ResponseBody(Stream.value(bytes), 200);
}

void main() {
  late _MockDio dio;
  late ChatRepository repository;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = _MockDio();
    repository = ChatRepository(dio: dio);
  });

  void stubStream(ResponseBody body) {
    when(
      () => dio.post<ResponseBody>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/chat/'),
        data: body,
      ),
    );
  }

  test('parses text, action and done events', () async {
    stubStream(
      _sse([
        'data: {"text": "Half a banana now, "}\n\n',
        'data: {"text": "water on the way."}\n\n',
        'data: {"action": "food_logged", "data": {"name": "Banana", "calories": 90}}\n\n',
        'data: {"done": true}\n\n',
      ]),
    );

    final events = await repository
        .send(sessionId: 's1', message: 'About to head out')
        .toList();

    expect(events, hasLength(4));
    expect((events[0] as ChatText).text, 'Half a banana now, ');
    expect((events[1] as ChatText).text, 'water on the way.');
    final action = events[2] as ChatAction;
    expect(action.action, 'food_logged');
    expect(action.data?['calories'], 90);
    expect(events[3], isA<ChatDone>());
  });

  test('sends session, message and mode in the body', () async {
    stubStream(_sse(['data: {"done": true}\n\n']));

    await repository
        .send(sessionId: 's1', message: 'hello', mode: 'voice')
        .toList();

    final captured =
        verify(
              () => dio.post<ResponseBody>(
                '/chat/',
                data: captureAny(named: 'data'),
                options: any(named: 'options'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured['session_id'], 's1');
    expect(captured['message'], 'hello');
    expect(captured['mode'], 'voice');
  });

  test('ignores malformed payloads and non-data lines', () async {
    stubStream(
      _sse([
        ': keepalive\n\n',
        'data: not-json\n\n',
        'data: {"text": "Hi."}\n\n',
        'data: {"done": true}\n\n',
      ]),
    );

    final events = await repository
        .send(sessionId: 's1', message: 'yo')
        .toList();

    expect(events, hasLength(2));
    expect((events[0] as ChatText).text, 'Hi.');
    expect(events[1], isA<ChatDone>());
  });

  test('supports the legacy [DONE] sentinel', () async {
    stubStream(_sse(['data: {"text": "Hey."}\n\n', 'data: [DONE]\n\n']));

    final events = await repository
        .send(sessionId: 's1', message: 'yo')
        .toList();

    expect(events.last, isA<ChatDone>());
  });

  test('surfaces error events as ChatFailure', () async {
    stubStream(
      _sse([
        'data: {"error": "AI service error, please try again."}\n\n',
        'data: {"done": true}\n\n',
      ]),
    );

    final events = await repository
        .send(sessionId: 's1', message: 'yo')
        .toList();

    expect(
      (events.first as ChatFailure).message,
      'AI service error, please try again.',
    );
  });
}
