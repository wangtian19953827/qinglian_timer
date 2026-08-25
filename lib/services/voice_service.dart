import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  ValueChanged<String>? _onError;
  ValueChanged<String>? _onText;
  bool _initialized = false;
  bool _appActive = false;
  bool _wantsListening = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize({required ValueChanged<String> onError}) async {
    _onError = onError;
    if (_initialized) {
      return _speech.isAvailable;
    }
    _initialized = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _appActive && _wantsListening) {
          _startListening();
        }
      },
      onError: (error) => _onError?.call(error.errorMsg),
      debugLogging: false,
    );
    return _initialized;
  }

  Future<void> startListening(ValueChanged<String> onText) async {
    _onText = onText;
    _appActive = true;
    _wantsListening = true;
    await _startListening();
  }

  Future<void> resume({ValueChanged<String>? onText}) async {
    if (onText != null) {
      _onText = onText;
    }
    _appActive = true;
    if (_wantsListening) {
      await _startListening();
    }
  }

  Future<void> pause() async {
    _appActive = false;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> stopListening() async {
    _wantsListening = false;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> dispose() async {
    _wantsListening = false;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> _startListening() async {
    if (!_initialized ||
        !_appActive ||
        !_wantsListening ||
        _speech.isListening) {
      return;
    }
    final locale = await _preferredLocale();
    final options = SpeechListenOptions(
      listenFor: const Duration(hours: 12),
      pauseFor: const Duration(minutes: 5),
      localeId: locale,
      partialResults: true,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
    );
    await _speech.listen(
      onResult: (result) => _onText?.call(result.recognizedWords),
      listenOptions: options,
    );
  }

  Future<String?> _preferredLocale() async {
    final locales = await _speech.locales();
    if (locales.isEmpty) {
      return null;
    }
    for (final locale in locales) {
      if (locale.localeId == 'zh_CN') {
        return 'zh_CN';
      }
    }
    for (final locale in locales) {
      if (locale.localeId.startsWith('zh')) {
        return locale.localeId;
      }
    }
    return null;
  }
}