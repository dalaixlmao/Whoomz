/// Accumulates streamed text deltas and surfaces completed sentences.
/// Drives both the whisper→ink settle of streaming text and per-sentence TTS.
class SentenceBuffer {
  final _re = RegExp(r'''[.!?]["')\]]*\s''');

  String _buffer = '';

  /// Adds a delta; returns any sentences completed by it.
  List<String> add(String chunk) {
    _buffer += chunk;
    final completed = <String>[];
    var start = 0;
    for (final match in _re.allMatches(_buffer)) {
      final sentence = _buffer.substring(start, match.end).trim();
      if (sentence.isNotEmpty) completed.add(sentence);
      start = match.end;
    }
    _buffer = _buffer.substring(start);
    return completed;
  }

  /// Whatever is still unterminated — shown as the in-flight whisper.
  String get pending => _buffer;

  /// Returns and clears the remainder (call when the stream ends).
  String flush() {
    final rest = _buffer.trim();
    _buffer = '';
    return rest;
  }
}
