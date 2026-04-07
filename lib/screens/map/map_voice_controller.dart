import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum VoiceAssistantState { idle, listening, processing, success, error }

class MapVoiceController extends ChangeNotifier {
  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _lastCommand = '';
  String _feedbackMessage = '';

  VoiceAssistantState get state => _state;
  String get lastCommand => _lastCommand;
  String get feedbackMessage => _feedbackMessage;

  // External references (to be set by MapScreen)
  void Function(String)? onPostToChat;
  void Function(LatLng)? onAddToFavorites;
  void Function()? onScanFeatures;
  LatLng? currentPosition;
  String? currentETA;

  void startListening() {
    _state = VoiceAssistantState.listening;
    _feedbackMessage = "Te ascult...";
    notifyListeners();
  }

  void stopListening() {
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  Future<void> processCommand(String command) async {
    _lastCommand = command;
    _state = VoiceAssistantState.processing;
    _feedbackMessage = "Procesez: \"$command\"...";
    notifyListeners();

    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 1));

    final cmd = command.toLowerCase();

    try {
      if (cmd.contains('post') || cmd.contains('chat') || cmd.contains('spune')) {
        await _handleChatCommand(command);
      } else if (cmd.contains('favorit') || cmd.contains('salvează')) {
        await _handleFavoriteCommand();
      } else if (cmd.contains('scanăm') || cmd.contains('scanează') || cmd.contains('ce vezi')) {
        await _handleScanCommand();
      } else if (cmd.contains('eta') || cmd.contains('cât mai fac')) {
        await _handleETACommand();
      } else {
        _state = VoiceAssistantState.error;
        _feedbackMessage = "Nu am înțelteles comanda. Încearcă: 'Postează la social', 'Salvează la favorite' sau 'Scanează harta'.";
      }
    } catch (e) {
      _state = VoiceAssistantState.error;
      _feedbackMessage = "Eroare: $e";
    }

    notifyListeners();
    
    // Reset to idle after 3 seconds of success/error
    Future.delayed(const Duration(seconds: 3), () {
      if (_state != VoiceAssistantState.listening) {
        _state = VoiceAssistantState.idle;
        notifyListeners();
      }
    });
  }

  Future<void> _handleChatCommand(String command) async {
    // Extract message (rudimentary)
    String message = command.replaceAll(RegExp(r'^.*?(post|chat|spune)\\s+', caseSensitive: false), '');
    if (message.isEmpty || message == command) message = "Salutare vecini!";
    
    if (onPostToChat != null) {
      onPostToChat!(message);
      _state = VoiceAssistantState.success;
      _feedbackMessage = "Am postat în chat: \"$message\"";
    } else {
      throw "Modulul de Chat nu este disponibil.";
    }
  }

  Future<void> _handleFavoriteCommand() async {
    if (currentPosition != null && onAddToFavorites != null) {
      onAddToFavorites!(currentPosition!);
      _state = VoiceAssistantState.success;
      _feedbackMessage = "Locația curentă a fost salvată la favorite!";
    } else {
      throw "Nu pot determina locația sau modulul Favorite e inactiv.";
    }
  }

  Future<void> _handleScanCommand() async {
    if (onScanFeatures != null) {
      onScanFeatures!();
      _state = VoiceAssistantState.success;
      _feedbackMessage = "Scanez zona... Văd 3 șoferi disponibili și o parcare liberă.";
    } else {
      throw "Scanarea nu este disponibilă pe acest nivel de zoom.";
    }
  }

  Future<void> _handleETACommand() async {
    if (currentETA != null) {
      _state = VoiceAssistantState.success;
      _feedbackMessage = "Vei ajunge la destinație în $currentETA.";
    } else {
      _state = VoiceAssistantState.error;
      _feedbackMessage = "Nu ai o rută activă în acest moment.";
    }
  }
}
