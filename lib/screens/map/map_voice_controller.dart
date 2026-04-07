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
  void Function()? onAddToFavorites;
  void Function()? onScanFeatures;
  LatLng? currentPosition;
  String? currentETA;

  MapVoiceController({
    this.onPostToChat,
    this.onAddToFavorites,
    this.onScanFeatures,
  });

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

    // Logic for processing commands
    await Future.delayed(const Duration(seconds: 1));
    
    final lowerCommand = command.toLowerCase();
    if (lowerCommand.contains("chat") || lowerCommand.contains("mesaj") || lowerCommand.contains("postează")) {
        postToNeighborhoodChat(command.replaceAll(RegExp(r'chat|mesaj|postează', caseSensitive: false), "").trim());
    } else if (lowerCommand.contains("favorit") || lowerCommand.contains("salvează")) {
        addCurrentLocationToFavorites();
    } else if (lowerCommand.contains("scanează") || lowerCommand.contains("caută")) {
        scanNearbyFeatures();
    }
    
    _state = VoiceAssistantState.success;
    _feedbackMessage = "Comandă executată!";
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }
  
  // Explicit methods for voice actions
  void postToNeighborhoodChat(String msg) {
    onPostToChat?.call(msg);
    notifyListeners();
  }

  void addCurrentLocationToFavorites() {
    onAddToFavorites?.call();
    notifyListeners();
  }

  void scanNearbyFeatures() {
    onScanFeatures?.call();
    notifyListeners();
  }
}
