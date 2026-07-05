import 'package:flutter_test/flutter_test.dart';
import 'package:whoomz/features/quick_log/keypad_value.dart';

void main() {
  group('KeypadValue (kcal mode)', () {
    test('starts empty and displays 0', () {
      final value = KeypadValue(maxIntDigits: 4);
      expect(value.isEmpty, isTrue);
      expect(value.display, '0');
      expect(value.value, isNull);
    });

    test('groups thousands like the design (1,284)', () {
      final value = KeypadValue(maxIntDigits: 4);
      for (final d in ['1', '2', '8', '4']) {
        value.addDigit(d);
      }
      expect(value.display, '1,284');
      expect(value.value, 1284);
    });

    test('caps integer digits', () {
      final value = KeypadValue(maxIntDigits: 4);
      for (final d in ['9', '9', '9', '9', '9']) {
        value.addDigit(d);
      }
      expect(value.value, 9999);
    });

    test('replaces a lone leading zero', () {
      final value = KeypadValue(maxIntDigits: 4);
      value.addDigit('0');
      value.addDigit('5');
      expect(value.display, '5');
    });

    test('ignores dot when decimals are not allowed', () {
      final value = KeypadValue(maxIntDigits: 4);
      value.addDigit('4');
      value.addDot();
      value.addDigit('2');
      expect(value.display, '42');
    });

    test('backspace removes the last digit', () {
      final value = KeypadValue(maxIntDigits: 4);
      value.addDigit('4');
      value.addDigit('8');
      value.backspace();
      expect(value.display, '4');
      value.backspace();
      expect(value.isEmpty, isTrue);
      value.backspace();
      expect(value.isEmpty, isTrue);
    });
  });

  group('KeypadValue (weight mode)', () {
    KeypadValue weight() => KeypadValue(allowDecimal: true, maxIntDigits: 3);

    test('accepts one decimal place (172.4)', () {
      final value = weight();
      for (final d in ['1', '7', '2']) {
        value.addDigit(d);
      }
      value.addDot();
      value.addDigit('4');
      value.addDigit('9');
      expect(value.display, '172.4');
      expect(value.value, 172.4);
    });

    test('dot on empty value becomes 0.', () {
      final value = weight();
      value.addDot();
      expect(value.display, '0.');
      value.addDigit('5');
      expect(value.value, 0.5);
    });

    test('second dot is ignored', () {
      final value = weight();
      value.addDigit('9');
      value.addDot();
      value.addDot();
      value.addDigit('1');
      expect(value.display, '9.1');
    });

    test('set() from a chip renders cleanly', () {
      final value = weight();
      value.set(610);
      expect(value.display, '610');
      value.set(172.4);
      expect(value.display, '172.4');
    });
  });
}
