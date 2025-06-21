import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class STTController {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String lastWords = '';

  Future<void> initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
  }

  Future<void> startListening(
    Function(SpeechRecognitionResult) onResult,
  ) async {
    await _speechToText.listen(
      onResult: onResult,
      listenFor: const Duration(milliseconds: 20000),
      pauseFor: const Duration(milliseconds: 5000),
      localeId: 'es_MX',
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
  bool get isNotListening => !_speechToText.isListening;
  bool get isSpeechEnabled => _speechEnabled;
}