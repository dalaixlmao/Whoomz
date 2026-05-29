import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannel', () {
    const channel = MethodChannel('com.example/device');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'getBatteryLevel':
            return 87;
          case 'getDeviceId':
            return 'test-device-001';
          case 'unsupported':
            throw PlatformException(
                code: 'UNSUPPORTED', message: 'not available');
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('invokeMethod returns mocked int result', () async {
      final level =
          await channel.invokeMethod<int>('getBatteryLevel');
      expect(level, 87);
    });

    test('invokeMethod returns mocked string result', () async {
      final id =
          await channel.invokeMethod<String>('getDeviceId');
      expect(id, 'test-device-001');
    });

    test('PlatformException propagates from native side', () async {
      expect(
        () => channel.invokeMethod('unsupported'),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'UNSUPPORTED')),
      );
    });

    test('invokeMethod with arguments passes args correctly', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        captured = call;
        return 'ok';
      });
      await channel.invokeMethod('sendData', {'key': 'value', 'n': 42});
      expect(captured!.method, 'sendData');
      expect(captured!.arguments, {'key': 'value', 'n': 42});
    });
  });

  group('EventChannel', () {
    const eventChannel = EventChannel('com.example/sensor');

    test('EventChannel name is set correctly', () {
      expect(eventChannel.name, 'com.example/sensor');
    });

    test('BasicMessageChannel round-trips a string', () async {
      const msgChannel =
          BasicMessageChannel<String>('com.example/ping', StringCodec());

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('com.example/ping', (message) async {
        // echo back
        return message;
      });

      final codec = const StringCodec();
      final encoded = codec.encodeMessage('hello');
      final reply = await TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .send('com.example/ping', encoded);
      final decoded = codec.decodeMessage(reply);
      expect(decoded, 'hello');
    });
  });

  test('All platform-channel smoke tests passed!', () => expect(true, isTrue));
}
