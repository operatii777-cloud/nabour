
// Voice Interaction States - Stările interacțiunii vocale ca Gemini Voice
// Caracteristici: Stări clare și logice, Tranziții naturale, Gestionarea contextului, Flow-ul conversației

import 'dart:async';
import 'package:nabour_app/utils/logger.dart';

/// 🚗 Stările pentru flow-ul cursei
enum RideFlowState {
  /// 🚀 Starea inițială
  idle,
  
  /// 🎤 Ascultă comanda inițială
  listeningForInitialCommand,
  
  /// 🧠 Procesează comanda
  processingCommand,
  
  /// 🎯 Destinația a fost confirmată
  destinationConfirmed,
  
  /// 🎯 Așteaptă locația curentă (pickup)
  awaitingPickupLocation,
  
  /// ⏳ Așteaptă confirmarea
  awaitingConfirmation,
  
  /// ✅ Confirmarea a fost primită
  confirmationReceived,
  
  /// 🔍 Caută șoferi
  searchingDrivers,
  
  /// 🚗 Șoferii au fost găsiți
  driversFound,
  
  /// ⏳ Așteaptă confirmarea rezervării
  awaitingRideConfirmation,
  
  /// ✅ Rezervarea cursei a fost confirmată
  rideConfirmed,
  
  /// 🚗 Șoferul a fost selectat
  driverSelected,
  
  /// 💰 Prețul a fost confirmat
  priceConfirmed,
  
  /// ✅ Rezervarea a fost finalizată
  bookingFinalized,
  
  /// 🚀 Cursa a fost finalizată
  rideFinalized,
  
  /// ❓ Așteaptă clarificare
  awaitingClarification,
  
  /// 🎯 NOU: Așteaptă confirmarea adreselor
  awaitingAddressConfirmation,
  
  /// 🎯 NOU: Afișează opțiunile de cursă
  showingRideOptions,
  
  /// 🎯 NOU: Așteaptă selecția opțiunii
  awaitingRideOptionSelection,
  
  /// 🎯 NOU: Opțiunea de cursă a fost selectată
  rideOptionSelected,
  
  /// 🎯 NOU: Așteaptă confirmarea finală
  awaitingFinalRideConfirmation,
  
  /// 🎯 NOU: Trimite la Firebase
  sendingToFirebase,
  
  /// 🎯 NOU: Așteaptă răspunsul șoferului
  waitingForDriverResponse,
  
  /// 🎯 NOU: Șofer găsit
  driverFound,
  
  /// 🎯 NOU: Așteaptă acceptarea/refuzul șoferului
  awaitingDriverAcceptance,
  
  /// 🎯 NOU: Șofer acceptat
  rideAccepted,
  
  /// 🎯 NOU: Șofer refuzat
  driverRejected,
  
  /// 🚗 NOU: Șoferul este în drum
  driverEnRoute,
  
  /// 🚗 NOU: Șoferul a ajuns
  driverArrived,
  
  /// ✅ NOU: Cursa s-a terminat
  rideCompleted,

  /// 🗺️ Așteaptă selecția adresei din mai multe variante
  awaitingAddressSelection,

  /// ❌ Eroare
  error,
}

/// 🎤 Stările pentru procesarea vocală
enum VoiceProcessingState {
  /// 🚀 Inactiv
  idle,
  
  /// 🎧 Ascultă
  listening,
  
  /// 🧠 Gândește (procesează)
  thinking,
  
  /// 🗣️ Vorbește
  speaking,
  
  /// ⏳ Așteaptă
  waiting,
  
  /// ⏳ Așteaptă confirmarea (NOU - pentru conversații multi-turn)
  waitingForConfirmation,
  
  /// ✅ Confirmarea primită (NOU - pentru conversații multi-turn)
  confirmationReceived,
  
  /// ❌ Eroare
  error,
}

/// 🎯 Stările pentru conversația vocală (NOU - pentru management-ul multi-turn)
enum VoiceConversationState {
  /// 🚀 Inactiv
  idle,
  
  /// 🎧 Ascultă comanda inițială
  listeningForInitialCommand,
  
  /// 🧠 Procesează comanda
  processingCommand,
  
  /// 🎯 Destinația confirmată
  destinationConfirmed,
  
  /// ⏳ Așteaptă confirmarea
  waitingForConfirmation,
  
  /// ✅ Confirmarea primită
  confirmed,
  
  /// 🔄 Așteaptă clarificare
  awaitingClarification,
  
  /// ❌ Eroare
  error,
}

/// 🎭 Stările pentru emoțiile vocale
enum VoiceEmotion {
  /// 🎉 Fericit (confirmări, succes)
  happy,
  
  /// 💪 Încrezător (informații, confirmări)
  confident,
  
  /// 😌 Calm (instrucțiuni, clarificări)
  calm,
  
  /// ⚡ Urgent (alerte, notificări importante)
  urgent,
  
  /// 🤔 Curios (întrebări)
  curious,
  
  /// 😊 Prietenos (salutări, deschidere)
  friendly,
  
  /// 🎯 Direct (comenzi, instrucțiuni clare)
  direct,
}

/// 🎯 Manager-ul pentru conversația vocală (NOU - pentru multi-turn)
class VoiceConversationManager {
  /// 🎯 Starea curentă a conversației
  VoiceConversationState _currentState = VoiceConversationState.idle;
  
  /// 🎯 Contextul conversației
  VoiceConversationContext? _context;
  
  /// 🎯 Callback pentru schimbări de stare
  Function(VoiceConversationState)? _onStateChange;
  
  /// 🎯 Callback pentru confirmări
  Function(bool)? _onConfirmationReceived;
  
  /// 🎯 Timeout pentru confirmări
  Timer? _confirmationTimeout;
  
  /// 🎯 Starea curentă
  VoiceConversationState get currentState => _currentState;
  
  /// 🎯 Contextul curent
  VoiceConversationContext? get context => _context;
  
  /// 🎯 Setează callback-ul pentru schimbări de stare
  void setStateChangeCallback(Function(VoiceConversationState) callback) {
    _onStateChange = callback;
  }
  
  /// 🎯 Setează callback-ul pentru confirmări
  void setConfirmationCallback(Function(bool) callback) {
    _onConfirmationReceived = callback;
  }
  
  /// 🎯 Începe o nouă conversație
  void startConversation() {
    _updateState(VoiceConversationState.listeningForInitialCommand);
  }
  
  /// 🎯 Procesează o comandă
  void processCommand() {
    _updateState(VoiceConversationState.processingCommand);
  }
  
  /// 🎯 Confirmă destinația
  void confirmDestination() {
    _updateState(VoiceConversationState.destinationConfirmed);
  }
  
  /// 🎯 Așteaptă confirmarea
  void waitForConfirmation({Duration timeout = const Duration(seconds: 30)}) {
    _updateState(VoiceConversationState.waitingForConfirmation);
    
    // Setează timeout-ul pentru confirmare
    _confirmationTimeout?.cancel();
    _confirmationTimeout = Timer(timeout, () {
      _handleConfirmationTimeout();
    });
  }
  
  /// 🎯 Gestionează confirmarea primită
  void handleConfirmation(bool confirmed) {
    _confirmationTimeout?.cancel();
    
    if (confirmed) {
      _updateState(VoiceConversationState.confirmed);
      _onConfirmationReceived?.call(true);
    } else {
      _updateState(VoiceConversationState.awaitingClarification);
      _onConfirmationReceived?.call(false);
    }
  }
  
  /// 🎯 Gestionează timeout-ul pentru confirmare
  void _handleConfirmationTimeout() {
    Logger.warning('Confirmation timeout - resetting to idle', tag: 'CONVERSATION');
    _updateState(VoiceConversationState.idle);
    _onConfirmationReceived?.call(false);
  }
  
  /// 🎯 Resetează conversația
  void reset() {
    _confirmationTimeout?.cancel();
    _updateState(VoiceConversationState.idle);
    _context = null;
  }
  
  /// 🎯 Actualizează starea
  void _updateState(VoiceConversationState newState) {
    _currentState = newState;
    Logger.debug('State changed to: $newState', tag: 'CONVERSATION');
    _onStateChange?.call(newState);
  }
  
  /// 🧹 Cleanup
  void dispose() {
    _confirmationTimeout?.cancel();
    _onStateChange = null;
    _onConfirmationReceived = null;
  }
}

/// 🎯 Contextul conversației vocale
class VoiceConversationContext {
  /// 🚗 Starea curentă a cursei
  final RideFlowState rideState;
  
  /// 🎤 Starea curentă de procesare vocală
  final VoiceProcessingState processingState;
  
  /// 🎭 Emoția vocală curentă
  final VoiceEmotion currentEmotion;
  
  /// 📝 Istoricul conversației
  final List<String> conversationHistory;
  
  /// 🚗 Destinația curentă
  final String? currentDestination;
  
  /// 🚗 Pickup-ul curent
  final String? currentPickup;
  
  /// 💰 Prețul estimat
  final double? estimatedPrice;
  
  /// 🚗 Șoferii disponibili
  final List<String> availableDrivers;
  
  /// 🎯 Timestamp-ul ultimei interacțiuni
  final DateTime lastInteractionTime;
  
  /// 🎯 Nivelul de încredere al ultimului răspuns
  final double lastConfidenceLevel;
  
  VoiceConversationContext({
    required this.rideState,
    required this.processingState,
    required this.currentEmotion,
    required this.conversationHistory,
    this.currentDestination,
    this.currentPickup,
    this.estimatedPrice,
    required this.availableDrivers,
    required this.lastInteractionTime,
    required this.lastConfidenceLevel,
  });
  
  /// 📝 Creează o copie cu actualizări
  VoiceConversationContext copyWith({
    RideFlowState? rideState,
    VoiceProcessingState? processingState,
    VoiceEmotion? currentEmotion,
    List<String>? conversationHistory,
    String? currentDestination,
    String? currentPickup,
    double? estimatedPrice,
    List<String>? availableDrivers,
    DateTime? lastInteractionTime,
    double? lastConfidenceLevel,
  }) {
    return VoiceConversationContext(
      rideState: rideState ?? this.rideState,
      processingState: processingState ?? this.processingState,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      currentDestination: currentDestination ?? this.currentDestination,
      currentPickup: currentPickup ?? this.currentPickup,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      lastInteractionTime: lastInteractionTime ?? this.lastInteractionTime,
      lastConfidenceLevel: lastConfidenceLevel ?? this.lastConfidenceLevel,
    );
  }
  
  /// 📝 Convertește în JSON
  Map<String, dynamic> toJson() {
    return {
      'rideState': rideState.toString(),
      'processingState': processingState.toString(),
      'currentEmotion': currentEmotion.toString(),
      'conversationHistory': conversationHistory,
      'currentDestination': currentDestination,
      'currentPickup': currentPickup,
      'estimatedPrice': estimatedPrice,
      'availableDrivers': availableDrivers,
      'lastInteractionTime': lastInteractionTime.toIso8601String(),
      'lastConfidenceLevel': lastConfidenceLevel,
    };
  }
  
  /// 📝 Convertește din JSON
  factory VoiceConversationContext.fromJson(Map<String, dynamic> json) {
    return VoiceConversationContext(
      rideState: RideFlowState.values.firstWhere(
        (e) => e.toString() == json['rideState'],
        orElse: () => RideFlowState.idle,
      ),
      processingState: VoiceProcessingState.values.firstWhere(
        (e) => e.toString() == json['processingState'],
        orElse: () => VoiceProcessingState.idle,
      ),
      currentEmotion: VoiceEmotion.values.firstWhere(
        (e) => e.toString() == json['currentEmotion'],
        orElse: () => VoiceEmotion.friendly,
      ),
      conversationHistory: List<String>.from(json['conversationHistory'] ?? []),
      currentDestination: json['currentDestination'],
      currentPickup: json['currentPickup'],
      estimatedPrice: json['estimatedPrice']?.toDouble(),
      availableDrivers: List<String>.from(json['availableDrivers'] ?? []),
      lastInteractionTime: DateTime.parse(json['lastInteractionTime']),
      lastConfidenceLevel: (json['lastConfidenceLevel'] ?? 0.0).toDouble(),
    );
  }
  
  /// 🎯 Verifică dacă contextul e valid
  bool get isValid {
    return rideState != RideFlowState.error &&
           processingState != VoiceProcessingState.error &&
           lastInteractionTime.isAfter(DateTime.now().subtract(const Duration(hours: 1)));
  }
  
  /// 🎯 Verifică dacă e timpul să se reseteze
  bool get shouldReset {
    return lastInteractionTime.isBefore(DateTime.now().subtract(const Duration(minutes: 30)));
  }
  
  /// 🎯 Obține descrierea stării curente
  String get stateDescription {
    switch (rideState) {
      case RideFlowState.idle:
        return 'Salut, unde doriți să mergeți?';
      case RideFlowState.listeningForInitialCommand:
        return 'Vă ascult...';
      case RideFlowState.processingCommand:
        return 'Procesez comanda...';
      case RideFlowState.destinationConfirmed:
        return 'Destinația confirmată';
      case RideFlowState.awaitingPickupLocation:
        return 'În ce locație vă aflați?';
      case RideFlowState.awaitingConfirmation:
        return 'Aștept confirmarea...';
      case RideFlowState.confirmationReceived:
        return 'Confirmarea primită';
      case RideFlowState.searchingDrivers:
        return 'Caut șoferi...';
      case RideFlowState.driversFound:
        return 'Șoferi găsiți';
      case RideFlowState.awaitingRideConfirmation:
        return 'Aștept confirmarea rezervării...';
      case RideFlowState.rideConfirmed:
        return 'Rezervarea confirmată';
      case RideFlowState.driverSelected:
        return 'Șoferul selectat';
      case RideFlowState.priceConfirmed:
        return 'Prețul confirmat';
      case RideFlowState.bookingFinalized:
        return 'Rezervarea finalizată';
      case RideFlowState.rideFinalized:
        return 'Cursa finalizată';
      case RideFlowState.awaitingClarification:
        return 'Aștept clarificare...';
      // 🎯 NOU: Stările pentru integrarea cu UI
      case RideFlowState.awaitingAddressConfirmation:
        return 'Aștept confirmarea adreselor...';
      case RideFlowState.showingRideOptions:
        return 'Afișez opțiunile de cursă...';
      case RideFlowState.awaitingRideOptionSelection:
        return 'Aștept selecția opțiunii...';
      case RideFlowState.rideOptionSelected:
        return 'Opțiunea selectată';
      case RideFlowState.awaitingFinalRideConfirmation:
        return 'Aștept confirmarea finală...';
      case RideFlowState.sendingToFirebase:
        return 'Trimit la Firebase...';
      case RideFlowState.waitingForDriverResponse:
        return 'Aștept răspunsul șoferului...';
      case RideFlowState.driverFound:
        return 'Șofer găsit';
      case RideFlowState.awaitingDriverAcceptance:
        return 'Aștept acceptarea șoferului...';
      case RideFlowState.rideAccepted:
        return 'Șoferul acceptat';
      case RideFlowState.driverRejected:
        return 'Șoferul refuzat';
      // 🚗 NOU: Stările pentru status-ul real al cursei
      case RideFlowState.driverEnRoute:
        return 'Șoferul este în drum...';
      case RideFlowState.driverArrived:
        return 'Șoferul a ajuns!';
      case RideFlowState.rideCompleted:
        return 'Cursa s-a terminat';
      case RideFlowState.awaitingAddressSelection:
        return 'Selectați adresa dorită...';
      case RideFlowState.error:
        return 'Eroare - vă rog să încercați din nou';
    }
  }
}
