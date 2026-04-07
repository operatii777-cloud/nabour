import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ──────────────────────────────────────────────────────────────────

/// Status portofel tokeni (colecție `token_wallets`).
enum TokenWalletStatus {
  active,
  frozen,
  closed;

  String get value => name;

  static TokenWalletStatus fromValue(String? v) =>
      TokenWalletStatus.values.firstWhere(
        (e) => e.value == v,
        orElse: () => TokenWalletStatus.active,
      );
}

/// Status transfer direct (colecție `token_direct_transfers`).
enum DirectTransferStatus {
  completed,
  failed;

  String get value => name;

  static DirectTransferStatus fromValue(String? v) =>
      DirectTransferStatus.values.firstWhere(
        (e) => e.value == v,
        orElse: () => DirectTransferStatus.failed,
      );
}

/// Status cerere de plată (colecție `token_payment_requests`).
enum PaymentRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired;

  String get value => name;

  static PaymentRequestStatus fromValue(String? v) =>
      PaymentRequestStatus.values.firstWhere(
        (e) => e.value == v,
        orElse: () => PaymentRequestStatus.pending,
      );

  bool get isTerminal =>
      this == PaymentRequestStatus.accepted ||
      this == PaymentRequestStatus.declined ||
      this == PaymentRequestStatus.cancelled ||
      this == PaymentRequestStatus.expired;
}

/// Tipul intrării în jurnal (colecție `token_ledger`).
enum LedgerEntryType {
  directTransferDebit,
  directTransferCredit,
  paymentRequestDebit,
  paymentRequestCredit;

  String get firestoreKey {
    switch (this) {
      case LedgerEntryType.directTransferDebit:
        return 'direct_transfer_debit';
      case LedgerEntryType.directTransferCredit:
        return 'direct_transfer_credit';
      case LedgerEntryType.paymentRequestDebit:
        return 'payment_request_debit';
      case LedgerEntryType.paymentRequestCredit:
        return 'payment_request_credit';
    }
  }

  static LedgerEntryType fromFirestoreKey(String? key) =>
      LedgerEntryType.values.firstWhere(
        (e) => e.firestoreKey == key,
        orElse: () => LedgerEntryType.directTransferDebit,
      );
}

// ─── TokenWallet (token_wallets/{userId}) ───────────────────────────────────

/// Portofel de tokeni transferabili. Colecție rădăcină: `token_wallets/{userId}`.
///
/// Balanța (`balanceMinor`) este modificată **numai** din backend (Cloud Functions).
class TokenWalletTransfer {
  final String userId;
  final int balanceMinor;
  final DateTime updatedAt;
  final int version;
  final TokenWalletStatus status;

  const TokenWalletTransfer({
    required this.userId,
    required this.balanceMinor,
    required this.updatedAt,
    required this.version,
    required this.status,
  });

  factory TokenWalletTransfer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return TokenWalletTransfer(
      userId: doc.id,
      balanceMinor: (m['balanceMinor'] as num?)?.toInt() ?? 0,
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      version: (m['version'] as num?)?.toInt() ?? 0,
      status: TokenWalletStatus.fromValue(m['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'balanceMinor': balanceMinor,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'version': version,
        'status': status.value,
      };
}

// ─── TokenDirectTransfer (token_direct_transfers/{transferId}) ──────────────

/// Transfer direct de tokeni (fără acceptare). Colecție rădăcină:
/// `token_direct_transfers/{transferId}`.
class TokenDirectTransfer {
  final String transferId;
  final String fromUserId;
  final String toUserId;
  final int amountMinor;
  final String? note;
  final DateTime createdAt;
  final DirectTransferStatus status;
  final String? failureCode;
  final String? ledgerCorrelationId;
  final String? clientRequestId;

  const TokenDirectTransfer({
    required this.transferId,
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
    this.note,
    required this.createdAt,
    required this.status,
    this.failureCode,
    this.ledgerCorrelationId,
    this.clientRequestId,
  });

  factory TokenDirectTransfer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return TokenDirectTransfer(
      transferId: doc.id,
      fromUserId: m['fromUserId'] as String? ?? '',
      toUserId: m['toUserId'] as String? ?? '',
      amountMinor: (m['amountMinor'] as num?)?.toInt() ?? 0,
      note: m['note'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: DirectTransferStatus.fromValue(m['status'] as String?),
      failureCode: m['failureCode'] as String?,
      ledgerCorrelationId: m['ledgerCorrelationId'] as String?,
      clientRequestId: m['clientRequestId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amountMinor': amountMinor,
        if (note != null) 'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status.value,
        if (failureCode != null) 'failureCode': failureCode,
        if (ledgerCorrelationId != null) 'ledgerCorrelationId': ledgerCorrelationId,
        if (clientRequestId != null) 'clientRequestId': clientRequestId,
      };

  bool get isCompleted => status == DirectTransferStatus.completed;
  bool get isFailed => status == DirectTransferStatus.failed;
}

// ─── TokenPaymentRequest (token_payment_requests/{requestId}) ───────────────

/// Cerere de plată tokeni (cu acceptare obligatorie din partea plătitorului).
/// Colecție rădăcină: `token_payment_requests/{requestId}`.
class TokenPaymentRequest {
  final String requestId;
  final String payerId;
  final String payeeId;
  final String initiatorId;
  final int amountMinor;
  final String? note;
  final PaymentRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final DateTime? resolvedAt;
  final String? declineReason;
  final String? ledgerCorrelationId;

  const TokenPaymentRequest({
    required this.requestId,
    required this.payerId,
    required this.payeeId,
    required this.initiatorId,
    required this.amountMinor,
    this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.resolvedAt,
    this.declineReason,
    this.ledgerCorrelationId,
  });

  factory TokenPaymentRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return TokenPaymentRequest(
      requestId: doc.id,
      payerId: m['payerId'] as String? ?? '',
      payeeId: m['payeeId'] as String? ?? '',
      initiatorId: m['initiatorId'] as String? ?? '',
      amountMinor: (m['amountMinor'] as num?)?.toInt() ?? 0,
      note: m['note'] as String?,
      status: PaymentRequestStatus.fromValue(m['status'] as String?),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (m['resolvedAt'] as Timestamp?)?.toDate(),
      declineReason: m['declineReason'] as String?,
      ledgerCorrelationId: m['ledgerCorrelationId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'payerId': payerId,
        'payeeId': payeeId,
        'initiatorId': initiatorId,
        'amountMinor': amountMinor,
        if (note != null) 'note': note,
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
        if (declineReason != null) 'declineReason': declineReason,
        if (ledgerCorrelationId != null) 'ledgerCorrelationId': ledgerCorrelationId,
      };

  bool get isPending => status == PaymentRequestStatus.pending;
  bool get isExpired => status == PaymentRequestStatus.expired;
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}

// ─── TokenLedgerEntry (token_ledger/{entryId}) ──────────────────────────────

/// Intrare în jurnalul de audit al tokenilor. Colecție rădăcină:
/// `token_ledger/{entryId}`. Append-only; nicio scriere din client.
class TokenLedgerEntry {
  final String entryId;
  final String userId;
  final int deltaMinor;
  final LedgerEntryType type;
  final String counterpartyUserId;
  final String referenceType;
  final String referenceId;
  final String correlationGroupId;
  final int? balanceAfterMinor;
  final DateTime createdAt;

  const TokenLedgerEntry({
    required this.entryId,
    required this.userId,
    required this.deltaMinor,
    required this.type,
    required this.counterpartyUserId,
    required this.referenceType,
    required this.referenceId,
    required this.correlationGroupId,
    this.balanceAfterMinor,
    required this.createdAt,
  });

  factory TokenLedgerEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return TokenLedgerEntry(
      entryId: doc.id,
      userId: m['userId'] as String? ?? '',
      deltaMinor: (m['deltaMinor'] as num?)?.toInt() ?? 0,
      type: LedgerEntryType.fromFirestoreKey(m['type'] as String?),
      counterpartyUserId: m['counterpartyUserId'] as String? ?? '',
      referenceType: m['referenceType'] as String? ?? '',
      referenceId: m['referenceId'] as String? ?? '',
      correlationGroupId: m['correlationGroupId'] as String? ?? '',
      balanceAfterMinor: (m['balanceAfterMinor'] as num?)?.toInt(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isCredit => deltaMinor > 0;
  bool get isDebit => deltaMinor < 0;
}
