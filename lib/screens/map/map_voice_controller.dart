import 'package:flutter/foundation.dart';

/// Controller for managing the AI Voice Assistant logic and map interactions.
class MapVoiceController extends ChangeNotifier {
    bool _isSpeaking = false;
    String _currentStatus = 'Idle';

    bool get isSpeaking => _isSpeaking;
    String get currentStatus => _currentStatus;

    /// Initiates the proactive greeting from the AI.
    void startGreeting() {
          _isSpeaking = true;
          _currentStatus = 'Greeting user...';
          notifyListeners();

          // Logic: Trigger TTS for "Salut! Cu ce te pot ajuta?"
          print('AI: Salut! Cu ce te pot ajuta?');

          // After greeting, wait for user intent or show menu
    }

    /// Handles the "Ride" request intent.
    void handleRideRequest() {
          _currentStatus = 'Processing Ride Request';
          notifyListeners();

          // Contextual Logic: Fetch ETA from map data
          // Example: double etaMinutes = mapProvider.getETA();
          String message = "Identifying best route. I can get a ride here in about 5 minutes.";
          print('AI: $message');
    }

    /// Handles the "Call" request intent for a specific contact.
    void handleCallRequest(String contact) {
          _currentStatus = 'Calling $contact';
          notifyListeners();

          // Logic: Trigger system call for [contact]
          print('AI: Initiating call to $contact...');
    }

    /// Handles the "Message" request intent with contextual ETA.
    void handleMessageRequest(String contact, String message) {
          _currentStatus = 'Sending message to $contact';
          notifyListeners();

          // Contextual Logic: Append ETA if relevant
          // Example: String finalMessage = "$message. My ETA is 7 mins.";
          print('AI: Sending message to $contact: $message');
    }

    void stopSpeaking() {
          _isSpeaking = false;
          _currentStatus = 'Idle';
          notifyListeners();
    }
}
