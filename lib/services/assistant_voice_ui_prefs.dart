import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssistantVoiceUiPrefs {
  AssistantVoiceUiPrefs._();
  static final AssistantVoiceUiPrefs instance = AssistantVoiceUiPrefs._();

  static const String _prefKey = 'assistant_voice_ui_visible';

  final ValueNotifier<bool> visibilityNotifier = ValueNotifier<bool>(false);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getBool(_prefKey) ?? false;
    if (visibilityNotifier.value != v) {
      visibilityNotifier.value = v;
    }
  }

  Future<void> setVisible(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefKey, v);
    visibilityNotifier.value = v;
  }
}
