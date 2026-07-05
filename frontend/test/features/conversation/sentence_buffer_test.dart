import 'package:flutter_test/flutter_test.dart';
import 'package:whoomz/features/conversation/domain/sentence_buffer.dart';

void main() {
  test('completes sentences only at boundaries followed by whitespace', () {
    final buffer = SentenceBuffer();
    expect(buffer.add('Half a banana now, water on the way. '), [
      'Half a banana now, water on the way.',
    ]);
    expect(buffer.add("You'll feel it lift"), isEmpty);
    expect(buffer.pending, "You'll feel it lift");
    expect(buffer.flush(), "You'll feel it lift");
    expect(buffer.pending, isEmpty);
  });

  test('does not split decimals', () {
    final buffer = SentenceBuffer();
    expect(buffer.add('You logged 3.5 miles today. Nice work'), [
      'You logged 3.5 miles today.',
    ]);
    expect(buffer.pending, 'Nice work');
  });

  test('handles chunks that split mid-sentence', () {
    final buffer = SentenceBuffer();
    expect(buffer.add('Easy 5K to'), isEmpty);
    expect(buffer.add('night. Keep it conversational! Then rest'), [
      'Easy 5K tonight.',
      'Keep it conversational!',
    ]);
    expect(buffer.flush(), 'Then rest');
  });

  test('flush on empty buffer returns empty string', () {
    expect(SentenceBuffer().flush(), '');
  });
}
