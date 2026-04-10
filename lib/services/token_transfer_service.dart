import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/token_transfer_models.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/services/nabour_functions.dart';
import 'package:nabour_app/utils/logger.dart';

/// Rezultatul apelului unui Cloud Function pentru transfer / cerere.
class TokenTransferResult {
  final bool success;
  final String? transferId;
  final String? requestId;
  final String? ledgerCorrelationId;
  final String? errorCode;
  final String? errorMessage;

  const TokenTransferResult._({
    required this.success,
    this.transferId,
    this.requestId,
    this.ledgerCorrelationId,
    this.errorCode,
    this.errorMessage,
  });

  factory TokenTransferResult.transferOk({
    required String transferId,
    String? ledgerCorrelationId,
  }) =>
      TokenTransferResult._(
        success: true,
        transferId: transferId,
        ledgerCorrelationId: ledgerCorrelationId,
      );

  factory TokenTransferResult.requestOk({required String requestId}) =>
      TokenTransferResult._(success: true, requestId: requestId);

  factory TokenTransferResult.respondOk({
    required String requestId,
    String? ledgerCorrelationId,
  }) =>
      TokenTransferResult._(
        success: true,
        requestId: requestId,
        ledgerCorrelationId: ledgerCorrelationId,
      );

  factory TokenTransferResult.error({
    required String code,
    required String message,
  }) =>
      TokenTransferResult._(success: false, errorCode: code, errorMessage: message);
}

/// Serviciu pentru transferul de tokeni și gestionarea cererilor de plată.
///
/// Responsabilități:
///   - Apeluri Cloud Functions (createTokenDirectTransfer, createTokenPaymentRequest,
///     respondToTokenPaymentRequest, cancelTokenPaymentRequest)
///   - Stream-uri Firestore pentru inbox plătitor, istoric transferuri, ledger
///   - Citire sold portofel din `token_wallets/{userId}`
class TokenTransferService {
  static final TokenTransferService _instance = TokenTransferService._();
  factory TokenTransferService() => _instance;
  TokenTransferService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Collection references ────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _wallets =>
      _db.collection('token_wallets');

  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection('token_direct_transfers');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('token_payment_requests');

  CollectionReference<Map<String, dynamic>> get _ledger =>
      _db.collection('token_ledger');

  // ─── Wallet ───────────────────────────────────────────────────────────────

  /// Stream live al soldului portofelului transferabil al utilizatorului curent.
  Stream<TokenWalletTransfer?> get walletStream {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _wallets
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? TokenWalletTransfer.fromDoc(snap) : null);
  }

  /// Obține snapshot-ul portofelului o singură dată.
  Future<TokenWalletTransfer?> getWallet([String? userId]) async {
    final id = userId ?? _uid;
    if (id == null) return null;
    try {
      final snap = await _wallets.doc(id).get();
      if (!snap.exists) return null;
      return TokenWalletTransfer.fromDoc(snap);
    } catch (e) {
      Logger.error('getWallet error', error: e, tag: 'TokenTransferService');
      return null;
    }
  }

  /// Rezolvă textul introdus ca **UID** (`users/{id}` există) sau ca **număr de telefon**
  /// (câmpurile `phoneNumber` / `phoneE164`). Folosit pentru transfer și cereri de plată.
  ///
  /// Returnează eroare dacă nu există niciun utilizator, sau mai mulți pentru același număr.
  Future<({String? userId, String? error})> resolveCounterpartyUserId(
    String input,
  ) async {
    final raw = input.trim();
    if (raw.isEmpty) {
      return (userId: null, error: 'Introdu un număr de telefon sau ID-ul contului.');
    }

    try {
      final byDoc = await _db.collection('users').doc(raw).get();
      if (byDoc.exists) {
        return (userId: raw, error: null);
      }
    } catch (e) {
      Logger.warning('resolveCounterpartyUserId doc: $e', tag: 'TokenTransferService');
    }

    final candidates = ContactsService.phoneLookupCandidates(raw).toList();
    if (candidates.isEmpty) {
      return (
        userId: null,
        error: 'Nu am găsit utilizator. Verifică numărul sau ID-ul din profilul Nabour.',
      );
    }

    final uids = <String>{};
    const batchSize = 10;
    for (var i = 0; i < candidates.length; i += batchSize) {
      final batch = candidates.skip(i).take(batchSize).toList();
      try {
        final s1 =
            await _db.collection('users').where('phoneNumber', whereIn: batch).get();
        for (final d in s1.docs) {
          uids.add(d.id);
        }
      } catch (e) {
        Logger.warning('resolveCounterpartyUserId phoneNumber: $e',
            tag: 'TokenTransferService');
      }
      try {
        final s2 =
            await _db.collection('users').where('phoneE164', whereIn: batch).get();
        for (final d in s2.docs) {
          uids.add(d.id);
        }
      } catch (e) {
        Logger.warning('resolveCounterpartyUserId phoneE164: $e',
            tag: 'TokenTransferService');
      }
    }

    if (uids.isEmpty) {
      return (
        userId: null,
        error: 'Nu am găsit utilizator cu acest număr. Poți folosi ID-ul din Profil.',
      );
    }
    if (uids.length > 1) {
      return (
        userId: null,
        error: 'Mai mulți utilizatori pentru acest număr. Folosește ID-ul exact al contului.',
      );
    }
    return (userId: uids.first, error: null);
  }

  // ─── Cloud Functions — Transfer direct ───────────────────────────────────

  /// Inițiază un transfer direct de tokeni. `clientRequestId` este obligatoriu
  /// pentru idempotency; generați un UUID pe client și reutilizați-l la retry.
  Future<TokenTransferResult> createDirectTransfer({
    required String toUserId,
    required int amountMinor,
    String? note,
    required String clientRequestId,
  }) async {
    try {
      final result = await NabourFunctions.instance
          .httpsCallable('createTokenDirectTransfer')
          .call({
        'toUserId': toUserId,
        'amountMinor': amountMinor,
        if (note != null) 'note': note,
        'clientRequestId': clientRequestId,
      });
      final data = result.data as Map<dynamic, dynamic>;
      return TokenTransferResult.transferOk(
        transferId: data['transferId'] as String,
        ledgerCorrelationId: data['ledgerCorrelationId'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        'createDirectTransfer: ${e.code} ${e.message}',
        error: e,
        tag: 'TokenTransferService',
      );
      return TokenTransferResult.error(code: e.code, message: e.message ?? e.code);
    } catch (e) {
      Logger.error('createDirectTransfer error', error: e, tag: 'TokenTransferService');
      return TokenTransferResult.error(code: 'internal', message: e.toString());
    }
  }

  // ─── Cloud Functions — Cerere de plată ───────────────────────────────────

  /// Creează o cerere de plată tokeni. Utilizatorul curent devine beneficiarul;
  /// `payerId` este cel care trebuie să accepte.
  Future<TokenTransferResult> createPaymentRequest({
    required String payerId,
    required int amountMinor,
    String? note,
  }) async {
    try {
      final result = await NabourFunctions.instance
          .httpsCallable('createTokenPaymentRequest')
          .call({
        'payerId': payerId,
        'amountMinor': amountMinor,
        if (note != null) 'note': note,
      });
      final data = result.data as Map<dynamic, dynamic>;
      return TokenTransferResult.requestOk(requestId: data['requestId'] as String);
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        'createPaymentRequest: ${e.code} ${e.message}',
        error: e,
        tag: 'TokenTransferService',
      );
      return TokenTransferResult.error(code: e.code, message: e.message ?? e.code);
    } catch (e) {
      Logger.error('createPaymentRequest error', error: e, tag: 'TokenTransferService');
      return TokenTransferResult.error(code: 'internal', message: e.toString());
    }
  }

  /// Răspunde la o cerere de plată. `action` este `'accept'` sau `'decline'`.
  Future<TokenTransferResult> respondToPaymentRequest({
    required String requestId,
    required String action, // 'accept' | 'decline'
    String? declineReason,
  }) async {
    assert(action == 'accept' || action == 'decline', 'action must be accept or decline');
    try {
      final result = await NabourFunctions.instance
          .httpsCallable('respondToTokenPaymentRequest')
          .call({
        'requestId': requestId,
        'action': action,
        if (declineReason != null) 'declineReason': declineReason,
      });
      final data = result.data as Map<dynamic, dynamic>;
      return TokenTransferResult.respondOk(
        requestId: data['requestId'] as String,
        ledgerCorrelationId: data['ledgerCorrelationId'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        'respondToPaymentRequest: ${e.code} ${e.message}',
        error: e,
        tag: 'TokenTransferService',
      );
      return TokenTransferResult.error(code: e.code, message: e.message ?? e.code);
    } catch (e) {
      Logger.error('respondToPaymentRequest error', error: e, tag: 'TokenTransferService');
      return TokenTransferResult.error(code: 'internal', message: e.toString());
    }
  }

  /// Anulează o cerere de plată pendinte. Poate fi apelat numai de `initiatorId`.
  Future<TokenTransferResult> cancelPaymentRequest(String requestId) async {
    try {
      final result = await NabourFunctions.instance
          .httpsCallable('cancelTokenPaymentRequest')
          .call({'requestId': requestId});
      final data = result.data as Map<dynamic, dynamic>;
      return TokenTransferResult.respondOk(requestId: data['requestId'] as String);
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        'cancelPaymentRequest: ${e.code} ${e.message}',
        error: e,
        tag: 'TokenTransferService',
      );
      return TokenTransferResult.error(code: e.code, message: e.message ?? e.code);
    } catch (e) {
      Logger.error('cancelPaymentRequest error', error: e, tag: 'TokenTransferService');
      return TokenTransferResult.error(code: 'internal', message: e.toString());
    }
  }

  // ─── Streams — inbox plătitor ─────────────────────────────────────────────

  /// Stream cereri pending în care utilizatorul curent este plătitor (inbox).
  Stream<List<TokenPaymentRequest>> get pendingPayerRequestsStream {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _requests
        .where('payerId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TokenPaymentRequest.fromDoc(d)).toList());
  }

  /// Stream cereri pending în care utilizatorul curent este beneficiar (trimise de el).
  Stream<List<TokenPaymentRequest>> get pendingPayeeRequestsStream {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _requests
        .where('payeeId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TokenPaymentRequest.fromDoc(d)).toList());
  }

  // ─── Streams — istoric ────────────────────────────────────────────────────

  /// Istoric transferuri directe (trimise și primite) ale utilizatorului curent.
  /// Returnează transferuri în care userul este expeditor sau destinatar,
  /// ordonate descrescător după `createdAt`.
  Future<List<TokenDirectTransfer>> getTransferHistory({int limit = 30}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final fromSnap = await _transfers
          .where('fromUserId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final toSnap = await _transfers
          .where('toUserId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final all = <String, TokenDirectTransfer>{};
      for (final d in [...fromSnap.docs, ...toSnap.docs]) {
        all[d.id] = TokenDirectTransfer.fromDoc(d);
      }
      final sorted = all.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted.take(limit).toList();
    } catch (e) {
      Logger.error('getTransferHistory error', error: e, tag: 'TokenTransferService');
      return [];
    }
  }

  /// Istoric cereri de plată (rezolvate) în care userul este participant.
  Future<List<TokenPaymentRequest>> getRequestHistory({int limit = 30}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final payerSnap = await _requests
          .where('payerId', isEqualTo: uid)
          .where('status', whereIn: ['accepted', 'declined', 'cancelled', 'expired'])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final payeeSnap = await _requests
          .where('payeeId', isEqualTo: uid)
          .where('status', whereIn: ['accepted', 'declined', 'cancelled', 'expired'])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final all = <String, TokenPaymentRequest>{};
      for (final d in [...payerSnap.docs, ...payeeSnap.docs]) {
        all[d.id] = TokenPaymentRequest.fromDoc(d);
      }
      final sorted = all.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted.take(limit).toList();
    } catch (e) {
      Logger.error('getRequestHistory error', error: e, tag: 'TokenTransferService');
      return [];
    }
  }

  /// Obține o singură cerere de plată după ID.
  Future<TokenPaymentRequest?> getPaymentRequest(String requestId) async {
    try {
      final snap = await _requests.doc(requestId).get();
      if (!snap.exists) return null;
      return TokenPaymentRequest.fromDoc(snap);
    } catch (e) {
      Logger.error('getPaymentRequest error', error: e, tag: 'TokenTransferService');
      return null;
    }
  }

  /// Stream live pentru o singură cerere de plată (detaliu).
  Stream<TokenPaymentRequest?> paymentRequestStream(String requestId) {
    return _requests.doc(requestId).snapshots().map(
          (snap) => snap.exists ? TokenPaymentRequest.fromDoc(snap) : null,
        );
  }

  // ─── Ledger ───────────────────────────────────────────────────────────────

  /// Ultimele [limit] intrări din jurnalul de audit al utilizatorului curent.
  Future<List<TokenLedgerEntry>> getLedgerHistory({int limit = 30}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snap = await _ledger
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => TokenLedgerEntry.fromDoc(d)).toList();
    } catch (e) {
      Logger.error('getLedgerHistory error', error: e, tag: 'TokenTransferService');
      return [];
    }
  }
}
