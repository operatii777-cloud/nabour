/// Model pentru mesaje rapide (quick replies)
class QuickReply {
  final String id;
  final String text;
  final String? icon; // Emoji sau icon name
  final QuickReplyCategory category;

  const QuickReply({
    required this.id,
    required this.text,
    this.icon,
    this.category = QuickReplyCategory.general,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      if (icon != null) 'icon': icon,
      'category': category.name,
    };
  }

  factory QuickReply.fromMap(Map<String, dynamic> map) {
    return QuickReply(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      icon: map['icon'],
      category: QuickReplyCategory.values.firstWhere(
        (e) => e.name == (map['category'] ?? 'general'),
        orElse: () => QuickReplyCategory.general,
      ),
    );
  }
}

enum QuickReplyCategory {
  general,
  driver,
  passenger,
  arrival,
  location,
}

/// Mesaje rapide predefinite pentru șoferi
class DriverQuickReplies {
  static const List<QuickReply> replies = [
    QuickReply(
      id: 'driver_arrived',
      text: 'Am ajuns la locația de preluare',
      icon: '✅',
      category: QuickReplyCategory.arrival,
    ),
    QuickReply(
      id: 'driver_soon',
      text: 'Sunt în curând, aproximativ 2-3 minute',
      icon: '⏱️',
      category: QuickReplyCategory.arrival,
    ),
    QuickReply(
      id: 'driver_waiting',
      text: 'Aștept la intrare',
      icon: '📍',
      category: QuickReplyCategory.location,
    ),
    QuickReply(
      id: 'driver_cant_find',
      text: 'Nu vă găsesc. Vă rog să mă sunați',
      icon: '📞',
    ),
    QuickReply(
      id: 'driver_traffic',
      text: 'Sunt în trafic, voi întârzia puțin',
      icon: '🚗',
    ),
  ];
}

/// Mesaje rapide predefinite pentru pasageri
class PassengerQuickReplies {
  static const List<QuickReply> replies = [
    QuickReply(
      id: 'passenger_waiting',
      text: 'Aștept la intrare',
      icon: '📍',
      category: QuickReplyCategory.location,
    ),
    QuickReply(
      id: 'passenger_coming',
      text: 'Vin imediat',
      icon: '🏃',
    ),
    QuickReply(
      id: 'passenger_delay',
      text: 'Îmi pare rău, voi întârzia 2-3 minute',
      icon: '⏰',
    ),
    QuickReply(
      id: 'passenger_ready',
      text: 'Sunt gata, vă aștept',
      icon: '✅',
    ),
    QuickReply(
      id: 'passenger_thanks',
      text: 'Mulțumesc!',
      icon: '🙏',
    ),
  ];
}

