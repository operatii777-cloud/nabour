import 'package:flutter/foundation.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🤖 Voice UI Automation Registry
/// Acționează ca un "DOM" sau "Playwright" pentru asistentul vocal.
/// Permite înregistrarea și execuția dinamică a oricărei funcții din UI.
class VoiceUIAutomationRegistry {
  static final VoiceUIAutomationRegistry _instance = VoiceUIAutomationRegistry._internal();
  factory VoiceUIAutomationRegistry() => _instance;
  VoiceUIAutomationRegistry._internal();

  /// Mapare ID widget -> Callback funcție
  final Map<String, VoidCallback> _callbacks = {};
  
  /// Mapare ID widget -> Callback cu parametri
  final Map<String, Function(Map<String, dynamic>)> _parameterizedCallbacks = {};

  /// Înregistrează o acțiune simplă (ex: apăsare buton)
  void registerAction(String id, VoidCallback action) {
    _callbacks[id] = action;
    Logger.info('Registered voice action: $id', tag: 'UI_AUTOMATION');
  }

  /// Înregistrează o acțiune complexă (ex: introducere text, selectare valoare)
  void registerParameterizedAction(String id, Function(Map<String, dynamic>) action) {
    _parameterizedCallbacks[id] = action;
    Logger.info('Registered parameterized voice action: $id', tag: 'UI_AUTOMATION');
  }

  /// Elimină o acțiune la dispose-ul widget-ului
  void unregisterAction(String id) {
    _callbacks.remove(id);
    _parameterizedCallbacks.remove(id);
    Logger.debug('Unregistered voice action: $id', tag: 'UI_AUTOMATION');
  }

  /// Execută o acțiune după ID
  bool executeAction(String id, {Map<String, dynamic>? params}) {
    Logger.info('🤖 Voice Automation: Attempting to execute $id', tag: 'UI_AUTOMATION');
    
    if (params != null && _parameterizedCallbacks.containsKey(id)) {
      _parameterizedCallbacks[id]!(params);
      return true;
    }
    
    if (_callbacks.containsKey(id)) {
      _callbacks[id]!();
      return true;
    }

    Logger.warning('Action ID "$id" not found in Registry', tag: 'UI_AUTOMATION');
    return false;
  }

  /// Returnează toate acțiunile disponibile în acest moment (DOM-ul curent)
  List<String> get availableActions => [
    ..._callbacks.keys,
    ..._parameterizedCallbacks.keys,
  ];
}
