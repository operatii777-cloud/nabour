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
        errorMessage = 'Sold insuficient de tokeni';

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

  // ── Paths ─────────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _walletRef(String uid) =>
      _db.collection('users').doc(uid).collection('token_wallet').doc('wallet');

  CollectionReference<Map<String, dynamic>> _txRef(String uid) =>
      _db.collection('users').doc(uid).collection('token_transactions');

  String? get _currentUid => _auth.currentUser?.uid;

  // ── Wallet initialization ──────────────────────────────────────────────────

  /// Asigură că wallet-ul există. Apelat la login / înregistrare.
  Future<void> ensureWalletExists(String uid) async {
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
          description: 'Alocare inițială plan ${wallet.plan.displayName}',
        );

        Logger.info('Token wallet creat pentru $uid (${wallet.balance} tokeni)', tag: 'TokenService');
      } else {
        if (_auth.currentUser?.uid != uid) {
          Logger.debug(
            'ensureWalletExists: skip maintain — auth uid mismatch',
            tag: 'TokenService',
          );
          return;
        }
        await _invokeMaintainTokenWallet();
      }
    } catch (e) {
      Logger.error('Eroare la ensureWalletExists', error: e, tag: 'TokenService');
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

  /// Obține wallet-ul o singură dată (pentru verificări punctuale).
  Future<TokenWallet?> getWallet([String? uid]) async {
    final id = uid ?? _currentUid;
    if (id == null) return null;
    try {
      final snap = await _walletRef(id).get();
      if (!snap.exists || snap.data() == null) return null;
      return TokenWallet.fromMap(id, snap.data()!);
    } catch (e) {
      Logger.error('Eroare la getWallet', error: e, tag: 'TokenService');
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
      return const TokenDeductResult.error('Utilizator neautentificat');
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
          return const TokenDeductResult.error('Wallet negăsit');
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
        Logger.debug('Tokeni deduși: -$cost (${type.label}) → sold: ${result.newBalance}', tag: 'TokenService');
      } else {
        Logger.warning('Sold insuficient pentru ${type.label} (cost: $cost)', tag: 'TokenService');
      }

      return result;
    } catch (e) {
      Logger.error('Eroare la spend tokens', error: e, tag: 'TokenService');
      return TokenDeductResult.error('Eroare internă: $e');
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
      return const TokenDeductResult.error('Utilizator neautentificat');
    }
    if (amount <= 0) {
      final wallet = await getWallet(uid);
      return TokenDeductResult.ok(wallet?.balance ?? 0);
    }

    try {
      final result = await _db.runTransaction<TokenDeductResult>((txn) async {
        final snap = await txn.get(_walletRef(uid));

        if (!snap.exists || snap.data() == null) {
          return const TokenDeductResult.error('Wallet negăsit');
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
          'Tokeni deduși: -$amount (${type.label}) → sold: ${result.newBalance}',
          tag: 'TokenService',
        );
      } else {
        Logger.warning(
          'Sold insuficient pentru ${type.label} (cost: $amount)',
          tag: 'TokenService',
        );
      }

      return result;
    } catch (e) {
      Logger.error('Eroare la spendAmount', error: e, tag: 'TokenService');
      return TokenDeductResult.error('Eroare internă: $e');
    }
  }

  // ── Adăugare tokeni (cumpărare / bonus) ───────────────────────────────────

  /// Adaugă tokeni în wallet (după cumpărare sau bonus).
  Future<void> addTokens(
    String uid,
    int amount,
    TokenTransactionType type, {
    required String description,
  }) async {
    try {
      await NabourFunctions.instance.httpsCallable('nabourWalletCredit').call({
        'action': 'topup',
        'amount': amount,
        'description': description,
      });
      Logger.info('Tokeni adăugați (CF): +$amount ($description)', tag: 'TokenService');
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        'addTokens CF: ${e.code} ${e.message}',
        error: e,
        tag: 'TokenService',
      );
      rethrow;
    } catch (e) {
      Logger.error('Eroare la addTokens', error: e, tag: 'TokenService');
      rethrow;
    }
  }

  // ── Reset lunar / credite — Cloud Functions ───────────────────────────────

  Future<void> _invokeMaintainTokenWallet() async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final user = _auth.currentUser;
        if (user == null) {
          Logger.debug('nabourMaintainTokenWallet: skip — no user', tag: 'TokenService');
          return;
        }
        // Forțează token proaspăt după cold start (înainte era race cu App Check / auth).
        await user.getIdToken(attempt > 0);
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }

        await NabourFunctions.instance
            .httpsCallable('nabourMaintainTokenWallet')
            .call();
        return;
      } on FirebaseFunctionsException catch (e) {
        final code = e.code.toLowerCase();
        final transient = code == 'unauthenticated' ||
            code == 'unavailable' ||
            code == 'deadline-exceeded';
        if (transient && attempt < maxAttempts - 1) {
          final step = (1 << attempt).clamp(1, 8);
          await Future<void>.delayed(Duration(milliseconds: 400 * step));
          continue;
        }
        Logger.warning(
          'nabourMaintainTokenWallet: ${e.code} ${e.message}',
          tag: 'TokenService',
        );
        return;
      } catch (e) {
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        Logger.warning('nabourMaintainTokenWallet: $e', tag: 'TokenService');
        return;
      }
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
    Logger.info('Staff subscription aplicat: ${plan.name}', tag: 'TokenService');
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
        'Plan upgradat (CF): ${wallet.plan.name} → ${newPlan.name}',
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
      Logger.error('Eroare la getTransactionHistory', error: e, tag: 'TokenService');
      return [];
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
      Logger.warning('Nu s-a putut loga tranzacția: $e', tag: 'TokenService');
    }
  }
}
