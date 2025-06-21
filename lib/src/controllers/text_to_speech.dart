import 'package:flutter_tts/flutter_tts.dart';

class TTSController {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Callback para notificar cambios en el estado de habla
  Function(bool)? onSpeakingStateChanged;

  TTSController() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('es-US');
    await _flutterTts.setPitch(0.9);

    // Configurar callbacks del TTS
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      if (onSpeakingStateChanged != null) {
        onSpeakingStateChanged!(_isSpeaking);
      }
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      if (onSpeakingStateChanged != null) {
        onSpeakingStateChanged!(_isSpeaking);
      }
    });

    _flutterTts.setErrorHandler((message) {
      _isSpeaking = false;
      if (onSpeakingStateChanged != null) {
        onSpeakingStateChanged!(_isSpeaking);
      }
    });
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    if (onSpeakingStateChanged != null) {
      onSpeakingStateChanged!(_isSpeaking);
    }
  }

  bool get isSpeaking => _isSpeaking;
}