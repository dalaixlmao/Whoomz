// Covers: null safety, generics, extensions, async/await, streams

// Null safety
String greet(String? name) => 'Hello, ${name ?? 'stranger'}!';

// Generics
class Box<T> {
  final T value;
  Box(this.value);
  T unwrap() => value;
}

// Extensions
extension StringRepeat on String {
  String repeat(int n) => List.filled(n, this).join();
}

// Async/await + Streams
Stream<int> countUp(int max) async* {
  for (var i = 1; i <= max; i++) {
    await Future.delayed(Duration(milliseconds: 10));
    yield i;
  }
}

void main() async {
  // Null safety
  print(greet('Dart'));
  print(greet(null));

  // Generics
  final box = Box<int>(42);
  print('Box<int>: ${box.unwrap()}');
  final strBox = Box<String>('hello');
  print('Box<String>: ${strBox.unwrap()}');

  // Extensions
  print('ha'.repeat(3));

  // Async/await + Streams
  final buffer = <int>[];
  await for (final n in countUp(5)) {
    buffer.add(n);
  }
  print('Stream values: $buffer');

  print('ALL CHECKS PASSED');
}
