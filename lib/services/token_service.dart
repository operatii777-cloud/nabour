import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/nabour_functions.dart';
import 'package:nabour_app/utils/logger.dart';

/// Rezultatul unei operații de deducere de tokeni.
class TokenDeductResult {
  final bool success;
  final int newBalance;
  final String? errorMessage;

  const TokenDeductResult.ok(this.newBalance)
      : success = true,
        errorMessage = null;

  const TokenDeductResult.insufficient(this.newBalance)
      : success = false,
        errorMessage = 'Insufficient token balance';

  const TokenDeductResult.error(this.errorMessage)
      : success = false,
        newBalance = 0;
}

/// Serviciu central pentru gestionarea tokenilor Nabour.
///
/// Responsabilități:
///   - Crearea wallet-ului la primul login
///   - Verificarea soldului înainte de operații costisitoare
///   - Deducerea tokenilor cu tranzacție de audit
///   - Reset lunar automat
///   - Stream live al wallet-ului curent
class TokenService {
  static final TokenService _instance = TokenService._();
  factory TokenService() => _instance;
  TokenService._();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// O singură încercare amânată per sesiune dacă burst-ul inițial primește doar `unauthenticated`.
  static bool _deferredWalletMaintainScheduled = false;
  static bool _maintainInFlight = false;
  static bool _startupMaintainExecuted = false;
  static DateTime? _lastAutoMaintainAttemptAt;
  static const Duration _authWarmupTimeout = Duration(seconds: 6);
  static const Duration _autoMaintainMinInterval = Duration(seconds: 30);

  // ── Paths ─────────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _walletRef(String uid) =>
      _db.collection('users').doc(uid).collection('token_wallet').doc('wallet');

  CollectionReference<Map<String, dynamic>> _txRef(String uid) =>
      _db.collection('users').doc(uid).collection('token_transactions');

  String? get _currentUid => _auth.currentUser?.uid;

  // ── Wallet initialization ──────────────────────────────────────────────────

  /// Asigură că wallet-ul există. Apelat la login / înregistrare.
  Future<void> ensureWalletExists(
    String uid, {
    bool maintainExisting = true,
  }) async {
    try {
      final snap = await _walletRef(uid).get();
      if (!snap.exists) {
        final wallet = TokenWallet.newUser(uid);
        await _walletRef(uid).set(wallet.toMap());

        // Prima tranzacție: reset lunar inițial
        await _logTransaction(
          uid: uid,
          amount: wallet.balance,
          type: TokenTransactionType.monthlyReset,
          description: 'Initial allocation for ${wallet.plan.displayName} plan',
        );

        Logger.info('Token wallet created for $uid (${wallet.balance} tokens)', tag: 'TokenService');
      } else {
        if (!maintainExisting) return;
        if (_auth.currentUser?.uid != uid) {
          Logger.debug(
            'ensureWalletExists: skip maintain — auth uid mismatch',
            tag: 'TokenService',
          );
          return;
        }
        final now = DateTime.now();
        final last = _lastAutoMaintainAttemptAt;
        if (last != null && now.difference(last) < _autoMaintainMinInterval) {
          Logger.debug(
            'ensureWalletExists: skip maintain — throttled (${now.difference(last).inSeconds}s)',
            tag: 'TokenService',
          );
          return;
        }
        _lastAutoMaintainAttemptAt = now;
        await _invokeMaintainTokenWallet();
      }
    } catch (e) {
      Logger.error('Error in ensureWalletExists', error: e, tag: 'TokenService');
    }
  }

  // ── Stream live ────────────────────────────────────────────────────────────

  /// Stream live al wallet-ului utilizatorului curent.
  Stream<TokenWallet?> get walletStream {
    final uid = _currentUid;
    if (uid == null) return const Stream.empty();
    return _walletRef(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return TokenWallet.fromMap(uid, snap.data()!);
    });
  }

  /// Stream pentru portofelul TRANSFERABIL (P2P).
  Stream<Map<String, dynamic>?> get transferableWalletStream {
    final uid = _currentUid;
    if (uid == null) return const Stream.empty();
    return _db
        .doc('token_wallets/$uid')
        .snapshots()
        .map((s) => s.exists ? s.data() : null);
  }

  /// Obține wallet-ul o singură dată (pentru verificări punctuale).
  Future<TokenWallet?> getWallet([String? uid]) async {
    final id = uid ?? _currentUid;
    if (id == null) return null;
    try {
      final snap = await _walletRef(id).get();
      if (!snap.exists || snap.data() == null) return null;
      return TokenWallet.fromMap(id, snap.data()!);
    } catch (e) {
      Logger.error('Error in getWallet', error: e, tag: 'TokenService');
      return null;
    }
  }

  /// Obține soldul curent rapid.
  Future<int> getTokenBalance() async {
    final wallet = await getWallet();
    return wallet?.balance ?? 0;
  }

  // ── Deducere tokeni ────────────────────────────────────────────────────────

  /// Verifică dacă utilizatorul curent are suficienți tokeni pentru o acțiune.
  /// Nu deducere — doar verificare.
  Future<bool> canAfford(TokenTransactionType type) async {
    final uid = _currentUid;
    if (uid == null) return false;
    final wallet = await getWallet(uid);
    if (wallet == null) return false;
    if (wallet.isUnlimited) return true;
    return wallet.balance >= TokenCost.forType(type);
  }

  /// Deducere tokeni pentru o acțiune. Returnează [TokenDeductResult].
  ///
  /// Exemplu:
  /// ```dart
  /// final result = await TokenService().spend(TokenTransactionType.aiQuery);
  /// if (!result.success) { showError(result.errorMessage!); return; }
  /// ```
  Future<bool> spendTokens(int amount, String description) async {
    final uid = _currentUid;
    if (uid == null) return false;

    try {
      final result = await _db.runTransaction<bool>((txn) async {
        final snap = await txn.get(_walletRef(uid));
        if (!snap.exists) return false;

        final balance = (snap.data()?['balance'] as num?)?.toInt() ?? 0;
        final plan = snap.data()?['plan'] as String? ?? 'free';

        if (plan != 'unlimited' && balance < amount) return false;

        // Regulile Firestore: la plan unlimited soldul nu se schimbă (doar totalSpent ↑).
        if (plan == 'unlimited') {
          txn.update(_walletRef(uid), {
            'totalSpent': FieldValue.increment(amount),
          });
        } else {
          txn.update(_walletRef(uid), {
            'balance': FieldValue.increment(-amount),
            'totalSpent': FieldValue.increment(amount),
          });
        }
        return true;
      });

      if (result) {
        _logTransaction(
          uid: uid,
          amount: -amount,
          type: TokenTransactionType.purchase,
          description: description,
        );
      }
      return result;
    } catch (e) {
      Logger.error('Error in spendTokens: $e');
      return false;
    }
  }

  Future<TokenDeductResult> spend(
    TokenTransactionType type, {
    String? customDescription,
  }) async {
    final uid = _currentUid;
    if (uid == null) {
      return const TokenDeductResult.error('User not authenticated');
    }

    final cost = TokenCost.forType(type);
    if (cost == 0) {
      return const TokenDeductResult.ok(0); // acțiune gratuită
    }

    try {
      // Folosim tranzacție Firestore pentru consistență
      final result = await _db.runTransaction<TokenDeductResult>((txn) async {
        final snap = await txn.get(_walletRef(uid));

        if (!snap.exists || snap.data() == null) {
          return const TokenDeductResult.error('Wallet not found');
        }

        final wallet = TokenWallet.fromMap(uid, snap.data()!);

        if (!wallet.isUnlimited && wallet.balance < cost) {
          return TokenDeductResult.insufficient(wallet.balance);
        }

        final newBalance = wallet.isUnlimited
            ? wallet.balance
            : wallet.balance - cost;

        txn.update(_walletRef(uid), {
          'balance':    newBalance,
          'totalSpent': FieldValue.increment(cost),
        });

        return TokenDeductResult.ok(newBalance);
      });

      if (result.success) {
        // Log async (nu blochează)
        _logTransaction(
          uid: uid,
          amount: -cost,
          type: type,
          description: customDescription ?? type.label,
        );
        Logger.debug('Tokens deducted: -$cost (${type.label}) -> balance: ${result.newBalance}', tag: 'TokenService');
      } else {
        Logger.warning('Insufficient token balance for ${type.label} (cost: $cost)', tag: 'TokenService');
      }

      return result;
    } catch (e) {
      Logger.error('Error spending tokens', error: e, tag: 'TokenService');
      return TokenDeductResult.error('Internal error: $e');
    }
  }

  /// Deducere cu sumă variabilă (ex. anunț + N × Mystery Box). [type] apare în jurnalul de audit.
  Future<TokenDeductResult> spendAmount(
    int amount, {
    required TokenTransactionType type,
    String? customDescription,
  }) async {
    final uid = _currentUid;
    if (uid == null) {
      return const TokenDeductResult.error('User not authenticated');
    }
    if (amount <= 0) {
      final wallet = await getWallet(uid);
      return TokenDeductResult.ok(wallet?.balance ?? 0);
    }

    try {
      final result = await _db.runTransaction<TokenDeductResult>((txn) async {
        final snap = await txn.get(_walletRef(uid));

        if (!snap.exists || snap.data() == null) {
          return const TokenDeductResult.error('Wallet not found');
        }

        final wallet = TokenWallet.fromMap(uid, snap.data()!);

        if (!wallet.isUnlimited && wallet.balance < amount) {
          return TokenDeductResult.insufficient(wallet.balance);
        }

        final newBalance =
            wallet.isUnlimited ? wallet.balance : wallet.balance - amount;

        txn.update(_walletRef(uid), {
          'balance': newBalance,
          'totalSpent': FieldValue.increment(amount),
        });

        return TokenDeductResult.ok(newBalance);
      });

      if (result.success) {
        _logTransaction(
          uid: uid,
          amount: -amount,
          type: type,
          description: customDescription ?? type.label,
        );
        Logger.debug(
          'Tokens deducted: -$amount (${type.label}) -> balance: ${result.newBalance}',
          tag: 'TokenService',
        );
      } else {
        Logger.warning(
          'Insufficient token balance for ${type.label} (cost: $amount)',
          tag: 'TokenService',
        );
      }

      return result;
    } catch (e) {
      Logger.error('Error in spendAmount', error: e, tag: 'TokenService');
      return TokenDeductResult.error('Internal error: $e');
    }
  }

  // ── Adăugare tokeni (cumpărare / bonus) ───────────────────────────────────

  /// Adaugă tokeni în wallet (după cumpărare sau bonus).
  Future<void> addTokens(
    String uid,
    int amount,
    TokenTransactionType type, {
    required String description,
    bool isTransferable = false,
  }) async {
    try {
      await NabourFunctions.instance.httpsCallable('nabourWalletCredit').call({
        'action': 'topup',
        'amount': amount,
        'description': description,
        'isTransferable': isTransferable,
      });
      Logger.info(
        'Tokens added (CF): +$amount ($description, transferable: $isTransferable)',
        tag: 'TokenService',
      );
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        'addTokens CF: ${e.code} ${e.message}',
        error: e,
        tag: 'TokenService',
      );
      rethrow;
    } catch (e) {
      Logger.error('Error in addTokens', error: e, tag: 'TokenService');
      rethrow;
    }
  }

  // ── Reset lunar / credite — Cloud Functions ───────────────────────────────

  Future<void> _invokeMaintainTokenWallet() async {
    if (_maintainInFlight) return;
    _maintainInFlight = true;
    const maxAttempts = 3;
    try {
      final signedInAt = _auth.currentUser?.metadata.lastSignInTime;
      if (signedInAt != null) {
        final sinceSignIn = DateTime.now().difference(signedInAt);
        // Pe Android, lansarea GMS / App Check imediat după boot poate fi instabilă.
        if (sinceSignIn < const Duration(seconds: 45)) {
          Logger.info('TokenService: Waiting for stable auth session (signed in ${sinceSignIn.inSeconds}s ago)...', tag: 'TokenService');
          await Future<void>.delayed(const Duration(seconds: 15));
        }
      }
      await _waitForStableAuthSession();
      
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          final user = _auth.currentUser;
          if (user == null) {
            Logger.debug('nabourMaintainTokenWallet: skip — no user', tag: 'TokenService');
            return;
          }

          // Force fresh token to ensure App Check token is attached
          final token = await user.getIdToken(true);
          if (token == null || token.isEmpty) {
            if (attempt < maxAttempts - 1) {
              await Future<void>.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
              continue;
            }
            Logger.warning('nabourMaintainTokenWallet: empty token after refresh', tag: 'TokenService');
            unawaited(_scheduleDeferredMaintainRetry());
            return;
          }

          if (attempt > 0) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }

          Logger.info('TokenService: Attempting nabourMaintainTokenWallet (attempt ${attempt + 1})...', tag: 'TokenService');
          await NabourFunctions.instance
              .httpsCallable('nabourMaintainTokenWallet')
              .call();
          
          Logger.info('TokenService: nabourMaintainTokenWallet successful.', tag: 'TokenService');
          return;
        } on FirebaseFunctionsException catch (e) {
          final code = e.code.toLowerCase();
          final message = e.message?.toLowerCase() ?? '';
          
          // Debug mode resilience: handle App Check attestation failures gracefully.
          // In debug, `unauthenticated` almost always means App Check token not registered
          // in Firebase Console — retrying immediately won't help.
          final isAppCheckError = message.contains('app-check') || message.contains('attestation');

          if (isAppCheckError && kDebugMode) {
            Logger.warning('TokenService: App Check failure in DEBUG mode. Monthly reset may be delayed.', tag: 'TokenService');
            unawaited(_scheduleDeferredMaintainRetry());
            return;
          }

          if (kDebugMode && code == 'unauthenticated') {
            Logger.warning('TokenService: unauthenticated in debug — likely App Check not configured. Scheduling deferred retry.', tag: 'TokenService');
            unawaited(_scheduleDeferredMaintainRetry());
            return;
          }

          final transient = code == 'unauthenticated' ||
              code == 'unavailable' ||
              code == 'deadline-exceeded';

          if (transient && attempt < maxAttempts - 1) {
            final step = (1 << attempt).clamp(1, 10);
            Logger.info('TokenService: Transient error ($code), retrying in ${step * 0.5}s...', tag: 'TokenService');
            await Future<void>.delayed(Duration(milliseconds: 500 * step));
            continue;
          }
          
          if (code == 'unauthenticated') {
            Logger.warning('TokenService: nabourMaintainTokenWallet returning 401 Unauthenticated. Scheduling deferred retry.', tag: 'TokenService');
            unawaited(_scheduleDeferredMaintainRetry());
          } else {
            Logger.warning('TokenService: nabourMaintainTokenWallet error: ${e.code} ${e.message}', tag: 'TokenService');
          }
          return;
        } catch (e) {
          if (attempt < maxAttempts - 1) {
            await Future<void>.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
            continue;
          }
          Logger.warning('TokenService: nabourMaintainTokenWallet unexpected error: $e', tag: 'TokenService');
          return;
        }
      }
    } finally {
      _maintainInFlight = false;
    }
  }

  Future<void> maintainWalletOnStartupOnce() async {
    if (_startupMaintainExecuted) return;
    _startupMaintainExecuted = true;
    // Respect the same throttle as ensureWalletExists to prevent a second
    // call chain when autonomous_app_coordinator already ran maintain.
    final last = _lastAutoMaintainAttemptAt;
    if (last != null && DateTime.now().difference(last) < _autoMaintainMinInterval) {
      Logger.debug('maintainWalletOnStartupOnce: skip — throttled (${DateTime.now().difference(last).inSeconds}s since last attempt)', tag: 'TokenService');
      return;
    }
    _lastAutoMaintainAttemptAt = DateTime.now();
    await _invokeMaintainTokenWallet();
  }

  /// Pe tablete cu GMS instabil, primul lanț de apeluri poate eșua; după ~18s tokenul e adesea acceptat.
  Future<void> _scheduleDeferredMaintainRetry() async {
    if (_deferredWalletMaintainScheduled) return;
    _deferredWalletMaintainScheduled = true;
    try {
      final delays = <Duration>[
        const Duration(seconds: 18),
        const Duration(seconds: 35),
      ];
      for (final wait in delays) {
        await Future<void>.delayed(wait);
        final user = _auth.currentUser;
        if (user == null) return;
        await _waitForStableAuthSession();
        final token = await user.getIdToken(true);
        if (token == null || token.isEmpty) continue;
        await Future<void>.delayed(const Duration(milliseconds: 650));
        try {
          await NabourFunctions.instance
              .httpsCallable('nabourMaintainTokenWallet')
              .call();
          Logger.info(
            'nabourMaintainTokenWallet: succeeded after deferred retry',
            tag: 'TokenService',
          );
          return;
        } on FirebaseFunctionsException catch (e) {
          if (e.code.toLowerCase() != 'unauthenticated') {
            Logger.debug(
              'nabourMaintainTokenWallet: deferred retry - ${e.code}',
              tag: 'TokenService',
            );
            return;
          }
        }
      }
      Logger.debug(
        'nabourMaintainTokenWallet: deferred retry exhausted',
        tag: 'TokenService',
      );
    } catch (e) {
      Logger.debug(
        'nabourMaintainTokenWallet: deferred retry - $e',
        tag: 'TokenService',
      );
    } finally {
      _deferredWalletMaintainScheduled = false;
    }
  }

  Future<void> _waitForStableAuthSession() async {
    final current = _auth.currentUser;
    if (current == null) return;
    final uid = current.uid;
    try {
      await _auth
          .idTokenChanges()
          .firstWhere((u) => u != null && u.uid == uid)
          .timeout(_authWarmupTimeout);
    } catch (_) {
      // Timeout sau stream închis: continuăm best-effort cu userul curent.
    }
  }

  /// Forțează verificarea resetului lunar (server-side).
  Future<void> forceMonthlyReset(String uid) async {
    Logger.info('forceMonthlyReset → nabourMaintainTokenWallet', tag: 'TokenService');
    await _invokeMaintainTokenWallet();
  }

  /// Doar pentru e-mailuri în lista `STAFF_SUBSCRIPTION_EMAILS` pe Functions (implicit operatii.777@gmail.com).
  /// După deploy: autentifică-te cu acel cont și apelează din UI staff sau din consolă.
  Future<void> applyStaffSubscription(TokenPlan plan) async {
    await NabourFunctions.instance.httpsCallable('nabourStaffApplySubscription').call({
      'plan': plan.name,
    });
    Logger.info('Staff subscription applied: ${plan.name}', tag: 'TokenService');
    await _invokeMaintainTokenWallet();
  }

  // ── Upgrade plan ───────────────────────────────────────────────────────────

  /// Schimbă planul utilizatorului și acordă tokenele diferenței imediat.
  Future<void> upgradePlan(String uid, TokenPlan newPlan) async {
    final wallet = await getWallet(uid);
    if (wallet == null) return;

    try {
      await NabourFunctions.instance.httpsCallable('nabourWalletCredit').call({
        'action': 'upgrade',
        'plan': newPlan.name,
      });
      Logger.info(
        'Plan upgraded (CF): ${wallet.plan.name} -> ${newPlan.name}',
        tag: 'TokenService',
      );
      await _invokeMaintainTokenWallet();
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        'upgradePlan CF: ${e.code} ${e.message}',
        error: e,
        tag: 'TokenService',
      );
      rethrow;
    }
  }

  // ── Istoric tranzacții ─────────────────────────────────────────────────────

  /// Returnează ultimele [limit] tranzacții ale utilizatorului.
  Future<List<TokenTransaction>> getTransactionHistory({
    String? uid,
    int limit = 20,
  }) async {
    final id = uid ?? _currentUid;
    if (id == null) return [];
    try {
      final snap = await _txRef(id)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => TokenTransaction.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      Logger.error('Error in getTransactionHistory', error: e, tag: 'TokenService');
      return [];
    }
  }

  /// Șterge toate tranzacțiile din istoricul utilizatorului (max 500 per batch).
  Future<void> clearTransactionHistory({String? uid}) async {
    final id = uid ?? _currentUid;
    if (id == null) return;
    try {
      final snap = await _txRef(id).limit(500).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      Logger.error('Error clearing transaction history', error: e, tag: 'TokenService');
      rethrow;
    }
  }

  /// Permite altor servicii să logheze o tranzacție deja procesată (ex. într-o tranzacție externă).
  Future<void> logManualTransaction({
    required String uid,
    required int amount,
    required TokenTransactionType type,
    required String description,
  }) async {
    await _logTransaction(
      uid: uid,
      amount: amount,
      type: type,
      description: description,
    );
  }

  // ── Helper privat ──────────────────────────────────────────────────────────

  Future<void> _logTransaction({
    required String uid,
    required int amount,
    required TokenTransactionType type,
    required String description,
  }) async {
    try {
      if (amount == 0) return;
      await _txRef(uid).add(TokenTransaction(
        id: '',
        uid: uid,
        amount: amount,
        type: type,
        description: description,
        createdAt: DateTime.now(),
      ).toMap());
    } catch (e) {
      Logger.warning('Failed to log transaction: $e', tag: 'TokenService');
    }
  }

  /// Achiziționează un plan (abonament) folosind soldul transferabil (P2P).
  Future<void> purchasePlanWithTokens(String plan) async {
    try {
      await NabourFunctions.instance
          .httpsCallable('nabourPurchasePlanWithTokens')
          .call({'plan': plan});
      Logger.info('Plan $plan was purchased with tokens.',
          tag: 'TokenService');
    } on FirebaseFunctionsException catch (e) {
      Logger.error('purchasePlanWithTokens CF: ${e.code} ${e.message}',
          tag: 'TokenService');
      rethrow;
    } catch (e) {
      Logger.error('purchasePlanWithTokens: $e', tag: 'TokenService');
      rethrow;
    }
  }
}
