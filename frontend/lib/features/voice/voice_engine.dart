import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// On-device speech in, spoken replies out. The rest of the voice loop
/// (send transcript → stream reply → speak sentences) lives in the screen.
class VoiceEngine {
  VoiceEngine({SpeechToText? stt, FlutterTts? tts})
    : _stt = stt ?? SpeechToText(),
      _tts = tts ?? FlutterTts();

  final SpeechToText _stt;
  final FlutterTts _tts;

  bool _ready = false;
  double _minLevel = 0;
  double _maxLevel = 1;

  bool get isReady => _ready;
  bool get isListening => _stt.isListening;

  Future<bool> init() async {
    try {
      _ready = await _stt.initialize();
    } catch (_) {
      _ready = false;
    }
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.5);
    return _ready;
  }

  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    required void Function(double level) onLevel,
  }) async {
    if (!_ready) return;
    await _stt.listen(
      onResult: (SpeechRecognitionResult result) =>
          onResult(result.recognizedWords, result.finalResult),
      onSoundLevelChange: (double level) => onLevel(_normalize(level)),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  /// Sound level units differ per platform — track the observed range.
  double _normalize(double raw) {
    if (raw < _minLevel) _minLevel = raw;
    if (raw > _maxLevel) _maxLevel = raw;
    final span = _maxLevel - _minLevel;
    if (span <= 0) return 0;
    return ((raw - _minLevel) / span).clamp(0.0, 1.0);
  }

  Future<void> stopListening() => _stt.stop();

  /// Blocks until the utterance finishes — callers queue sentences with it.
  Future<void> speak(String sentence) => _tts.speak(sentence);

  Future<void> dispose() async {
    await _stt.cancel();
    await _tts.stop();
  }
}
