import 'package:intl/intl.dart';

/// Digit-entry model behind the quick-log keypad.
class KeypadValue {
  KeypadValue({
    this.allowDecimal = false,
    this.maxIntDigits = 4,
    this.maxDecimals = 1,
  });

  final bool allowDecimal;
  final int maxIntDigits;
  final int maxDecimals;

  String _raw = '';

  bool get isEmpty => _raw.isEmpty;

  double? get value => double.tryParse(_raw);

  void addDigit(String digit) {
    assert(digit.length == 1 && '0123456789'.contains(digit));
    final dot = _raw.indexOf('.');
    if (dot >= 0) {
      if (_raw.length - dot - 1 >= maxDecimals) return;
      _raw += digit;
      return;
    }
    if (_raw == '0') {
      _raw = digit;
      return;
    }
    if (_raw.length >= maxIntDigits) return;
    _raw += digit;
  }

  void addDot() {
    if (!allowDecimal || _raw.contains('.')) return;
    _raw = _raw.isEmpty ? '0.' : '$_raw.';
  }

  void backspace() {
    if (_raw.isEmpty) return;
    _raw = _raw.substring(0, _raw.length - 1);
  }

  void clear() => _raw = '';

  void set(double newValue) {
    _raw = newValue == newValue.truncateToDouble()
        ? newValue.toInt().toString()
        : newValue.toStringAsFixed(maxDecimals);
  }

  /// "1,284" · "172.4" · trailing dot preserved while typing ("172.")
  String get display {
    if (_raw.isEmpty) return '0';
    final dot = _raw.indexOf('.');
    final intPart = dot >= 0 ? _raw.substring(0, dot) : _raw;
    final rest = dot >= 0 ? _raw.substring(dot) : '';
    final grouped = NumberFormat('#,##0').format(int.parse(intPart));
    return '$grouped$rest';
  }
}
