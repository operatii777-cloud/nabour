class SmartSuggestion {
  final String id;
  final String label;          // "Acasă", "Serviciu", "Parc Herăstrău"
  final String address;
  final double latitude;
  final double longitude;
  final SmartSuggestionType type;
  final int frequencyScore;    // de câte ori a fost folosită

  const SmartSuggestion({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.frequencyScore,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'type': type.name,
        'frequencyScore': frequencyScore,
      };

  factory SmartSuggestion.fromJson(Map<String, dynamic> j) => SmartSuggestion(
        id: j['id'] ?? '',
        label: j['label'] ?? '',
        address: j['address'] ?? '',
        latitude: (j['latitude'] ?? 0.0).toDouble(),
        longitude: (j['longitude'] ?? 0.0).toDouble(),
        type: SmartSuggestionType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => SmartSuggestionType.frequent,
        ),
        frequencyScore: j['frequencyScore'] ?? 0,
      );
}

enum SmartSuggestionType {
  home,       // Adresa de acasă salvată
  work,       // Adresa de serviciu salvată
  frequent,   // Destinație frecventă din istoric
  timeBased,  // Sugestie bazată pe ora zilei
}
