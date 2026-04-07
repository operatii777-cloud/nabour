// Voice-specific models and enums for the Nabour Voice AI system

enum ConversationState {
  idle,
  listeningForInitialCommand,
  processingCommand,
  clarifyingAmbiguity,
  confirmingPickup,
  awaitingPickupConfirmation,
  listeningForNewPickup,
  presentingQuote,
  awaitingRideConfirmation,
  finalizingBooking,
  providingFeedback,
  awaitingPostBookingCommands,
  awaitingDestinationConfirmation,
  error,
}

class RideRequest {
  String id;
  String passengerId;
  String pickupLocation;
  String destination;
  double estimatedPrice;
  String category;
  String urgency;
  DateTime timestamp;
  String status;
  String paymentMethod;
  
  // 🎯 NOU: Câmpuri pentru datele AI
  String? passengerNotes;
  String? aiSessionId;
  bool isVoiceRequest;
  Map<String, dynamic>? aiConversationData;
  int numberOfPassengers;
  
  // ✅ FIX: Adaugă coordonate pentru validare
  double? pickupLatitude;
  double? pickupLongitude;
  double? destinationLatitude;
  double? destinationLongitude;

  /// Ca pe hartă: doar acești șoferi (UID) pot primi cursa. `null` = fără restricție (evită în producție).
  List<String>? allowedDriverUids;

  RideRequest({
    required this.id,
    required this.passengerId,
    required this.pickupLocation,
    required this.destination,
    required this.estimatedPrice,
    required this.category,
    required this.urgency,
    required this.timestamp,
    required this.status,
    this.paymentMethod = 'cash',
    // 🎯 NOU: Câmpuri pentru datele AI
    this.passengerNotes,
    this.aiSessionId,
    this.isVoiceRequest = true,
    this.aiConversationData,
    this.numberOfPassengers = 1,
    // ✅ FIX: Coordonate
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.allowedDriverUids,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passengerId': passengerId,
      'pickupLocation': pickupLocation,
      'destination': destination,
      'estimatedPrice': estimatedPrice,
      'category': category,
      'urgency': urgency,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      // 🎯 NOU: Câmpuri pentru datele AI
      'passengerNotes': passengerNotes,
      'aiSessionId': aiSessionId,
      'isVoiceRequest': isVoiceRequest,
      'aiConversationData': aiConversationData,
      'numberOfPassengers': numberOfPassengers,
      // ✅ FIX: Coordonate
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      if (allowedDriverUids != null && allowedDriverUids!.isNotEmpty)
        'allowedDriverUids': allowedDriverUids,
    };
  }

  factory RideRequest.fromMap(Map<String, dynamic> map) {
    return RideRequest(
      id: map['id'] ?? '',
      passengerId: map['passengerId'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      destination: map['destination'] ?? '',
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'standard',
      urgency: map['urgency'] ?? 'normal',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      // 🎯 NOU: Câmpuri pentru datele AI
      passengerNotes: map['passengerNotes'],
      aiSessionId: map['aiSessionId'],
      isVoiceRequest: map['isVoiceRequest'] ?? true,
      aiConversationData: map['aiConversationData'],
      numberOfPassengers: map['numberOfPassengers'] ?? 1,
      // ✅ FIX: Coordonate
      pickupLatitude: (map['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (map['pickupLongitude'] as num?)?.toDouble(),
      destinationLatitude: (map['destinationLatitude'] as num?)?.toDouble(),
      destinationLongitude: (map['destinationLongitude'] as num?)?.toDouble(),
      allowedDriverUids: map['allowedDriverUids'] != null
          ? List<String>.from(map['allowedDriverUids'] as List)
          : null,
    );
  }
}

class RideOffer {
  String id;
  String driverId;
  String driverName;
  String? driverPhoto;
  String carModel;
  String carColor;
  String licensePlate;
  Duration eta;
  double price;
  String paymentMethod;
  String destination;
  String category;
  String urgency;
  double estimatedPrice;
  String pickupLocation;
  double driverRating;
  List<String> carFeatures;

  RideOffer({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhoto,
    required this.carModel,
    required this.carColor,
    required this.licensePlate,
    required this.eta,
    required this.price,
    required this.paymentMethod,
    required this.destination,
    required this.category,
    required this.urgency,
    required this.estimatedPrice,
    required this.pickupLocation,
    required this.driverRating,
    required this.carFeatures,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhoto': driverPhoto,
      'carModel': carModel,
      'carColor': carColor,
      'licensePlate': licensePlate,
      'eta': eta.inSeconds,
      'price': price,
      'paymentMethod': paymentMethod,
      'destination': destination,
      'category': category,
      'urgency': urgency,
      'estimatedPrice': estimatedPrice,
      'pickupLocation': pickupLocation,
      'driverRating': driverRating,
      'carFeatures': carFeatures,
    };
  }

  factory RideOffer.fromMap(Map<String, dynamic> map) {
    return RideOffer(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhoto: map['driverPhoto'],
      carModel: map['carModel'] ?? '',
      carColor: map['carColor'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      eta: Duration(seconds: map['eta'] ?? 0),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'cash',
      destination: map['destination'] ?? '',
      category: map['category'] ?? 'standard',
      urgency: map['urgency'] ?? 'normal',
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      pickupLocation: map['pickupLocation'] ?? '',
      driverRating: (map['driverRating'] as num?)?.toDouble() ?? 0.0,
      carFeatures: List<String>.from(map['carFeatures'] ?? []),
    );
  }
}
