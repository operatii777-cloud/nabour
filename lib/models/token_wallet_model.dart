import 'package:cloud_firestore/cloud_firestore.dart';

/// Planurile de abonament disponibile în Nabour.
enum TokenPlan {
  free,
  basic,
  pro,
  unlimited;

  /// Tokeni gratuiți incluși lunar în plan.
  int get monthlyAllowance {
    switch (this) {
      case TokenPlan.free:      return 1000;
      case TokenPlan.basic:     return 10000;
      case TokenPlan.pro:       return 50000;
      case TokenPlan.unlimited: return 999999999;
    }
  }

  String get displayName {
    switch (this) {
      case TokenPlan.free:      return 'Gratuit';
      case TokenPlan.basic:     return 'Basic';
      case TokenPlan.pro:       return 'Pro';
      case TokenPlan.unlimited: return 'Unlimited';
    }
  }

  String get priceLabel {
    switch (this) {
      case TokenPlan.free:      return 'Gratuit';
      case TokenPlan.basic:     return '9 RON / lună';
      case TokenPlan.pro:       return '29 RON / lună';
      case TokenPlan.unlimited: return '49 RON / lună';
    }
  }
}

/// Tipul unei tranzacții de tokeni.
enum TokenTransactionType {
  aiQuery,
  routeCalc,
  geocoding,
  broadcastPost,
  purchase,
  monthlyReset,
  bonus,
  adminAdjust,
  businessOffer;

  String get label {
    switch (this) {
      case TokenTransactionType.aiQuery:       return 'Query AI';
      case TokenTransactionType.routeCalc:     return 'Calcul rută';
      case TokenTransactionType.geocoding:     return 'Geocoding';
      case TokenTransactionType.broadcastPost: return 'Post cursă';
      case TokenTransactionType.purchase:      return 'Cumpărare';
      case TokenTransactionType.monthlyReset:  return 'Reset lunar';
      case TokenTransactionType.bonus:         return 'Bonus';
      case TokenTransactionType.adminAdjust:   return 'Ajustare admin';
      case TokenTransactionType.businessOffer: return 'Anunț business';
    }
  }

  String get firestoreKey {
    switch (this) {
      case TokenTransactionType.aiQuery:       return 'ai_query';
      case TokenTransactionType.routeCalc:     return 'route_calc';
      case TokenTransactionType.geocoding:     return 'geocoding';
      case TokenTransactionType.broadcastPost: return 'broadcast_post';
      case TokenTransactionType.purchase:      return 'purchase';
      case TokenTransactionType.monthlyReset:  return 'monthly_reset';
      case TokenTransactionType.bonus:         return 'bonus';
      case TokenTransactionType.adminAdjust:   return 'admin_adjust';
      case TokenTransactionType.businessOffer: return 'business_offer';
    }
  }

  static TokenTransactionType fromFirestoreKey(String key) {
    return TokenTransactionType.values.firstWhere(
      (t) => t.firestoreKey == key,
      orElse: () => TokenTransactionType.adminAdjust,
    );
  }
}

/// Costul în tokeni pentru fiecare tip de acțiune.
class TokenCost {
  static const int aiQuery       = 10;
  static const int routeCalc     = 3;
  static const int geocoding     = 1;
  static const int broadcastPost = 1;
  static const int businessOffer = 500;

  /// Un slot Mystery Box pe hartă. La paritatea folosită în app pentru anunțuri (500 tok ≈ 5 lei), 50 tok ≈ 0,5 lei.
  static const int mysteryBoxSlot = 50;

  /// Cost suplimentar pentru [slots] cutii cu plafon; 0 dacă nelimitat / fără număr.
  static int mysteryBoxSlotsTokenCost(int slots) {
    if (slots <= 0) return 0;
    return slots * mysteryBoxSlot;
  }

  /// Total la publicare anunț + opțional cutii Mystery Box.
  static int businessOfferWithMysterySlots(int mysterySlots) =>
      businessOffer + mysteryBoxSlotsTokenCost(mysterySlots);

  /// Returnează costul pentru un tip de tranzacție.
  static int forType(TokenTransactionType type) {
    switch (type) {
      case TokenTransactionType.aiQuery:       return aiQuery;
      case TokenTransactionType.routeCalc:     return routeCalc;
      case TokenTransactionType.geocoding:     return geocoding;
      case TokenTransactionType.broadcastPost: return broadcastPost;
      case TokenTransactionType.businessOffer: return businessOffer;
      default: return 0;
    }
  }
}

/// Portofelul de tokeni al unui utilizator.
class TokenWallet {
  final String uid;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final TokenPlan plan;
  final DateTime resetAt;
  final DateTime? lastResetAt;
  final DateTime createdAt;

  const TokenWallet({
    required this.uid,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.plan,
    required this.resetAt,
    this.lastResetAt,
    required this.createdAt,
  });

  /// Procentul din alocarea lunară consumat (0.0 – 1.0).
  double get usageRatio {
    if (plan == TokenPlan.unlimited) return 0;
    final allowance = plan.monthlyAllowance;
    if (allowance <= 0) return 0;
    final spent = allowance - balance;
    return (spent / allowance).clamp(0.0, 1.0);
  }

  bool get hasTokens => balance > 0;
  bool get isUnlimited => plan == TokenPlan.unlimited;

  /// Tokeni rămași din alocarea lunară (poate fi negativ dacă a depășit).
  int get remaining => balance;

  factory TokenWallet.fromMap(String uid, Map<String, dynamic> m) {
    return TokenWallet(
      uid: uid,
      balance:      (m['balance']      as num?)?.toInt() ?? 0,
      totalEarned:  (m['totalEarned']  as num?)?.toInt() ?? 0,
      totalSpent:   (m['totalSpent']   as num?)?.toInt() ?? 0,
      plan: TokenPlan.values.firstWhere(
        (p) => p.name == (m['plan'] as String? ?? 'free'),
        orElse: () => TokenPlan.free,
      ),
      resetAt:     (m['resetAt']     as Timestamp?)?.toDate() ?? _nextMonthFirst(),
      lastResetAt: (m['lastResetAt'] as Timestamp?)?.toDate(),
      createdAt:   (m['createdAt']   as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'balance':      balance,
    'totalEarned':  totalEarned,
    'totalSpent':   totalSpent,
    'plan':         plan.name,
    'freeMonthlyAllowance': plan.monthlyAllowance,
    'resetAt':      Timestamp.fromDate(resetAt),
    if (lastResetAt != null) 'lastResetAt': Timestamp.fromDate(lastResetAt!),
    'createdAt':    Timestamp.fromDate(createdAt),
  };

  /// Wallet implicit pentru un user nou.
  factory TokenWallet.newUser(String uid) => TokenWallet(
    uid: uid,
    balance: TokenPlan.free.monthlyAllowance,
    totalEarned: TokenPlan.free.monthlyAllowance,
    totalSpent: 0,
    plan: TokenPlan.free,
    resetAt: _nextMonthFirst(),
    createdAt: DateTime.now(),
  );

  static DateTime _nextMonthFirst() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1);
  }
}

/// O tranzacție individuală de tokeni (log de audit).
class TokenTransaction {
  final String id;
  final String uid;
  final int amount;   // negativ = consum, pozitiv = adăugare
  final TokenTransactionType type;
  final String description;
  final DateTime createdAt;

  const TokenTransaction({
    required this.id,
    required this.uid,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory TokenTransaction.fromMap(String id, Map<String, dynamic> m) =>
      TokenTransaction(
        id: id,
        uid: m['uid'] as String? ?? '',
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        type: TokenTransactionType.fromFirestoreKey(m['type'] as String? ?? ''),
        description: m['description'] as String? ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'amount': amount,
    'type': type.firestoreKey,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
