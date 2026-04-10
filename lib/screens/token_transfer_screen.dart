import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/models/token_transfer_models.dart';
import 'package:nabour_app/services/token_transfer_service.dart';
import 'package:uuid/uuid.dart';
import 'package:nabour_app/core/ui/app_feedback.dart';

/// Ecran pentru transfer direct de tokeni și cereri de plată între utilizatori
/// (portofel `token_wallets`, backend Cloud Functions).
class TokenTransferScreen extends StatefulWidget {
  const TokenTransferScreen({super.key});

  @override
  State<TokenTransferScreen> createState() => _TokenTransferScreenState();
}

class _TokenTransferScreenState extends State<TokenTransferScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _svc = TokenTransferService();
  final _uuid = const Uuid();

  final _directToId = TextEditingController();
  final _directAmount = TextEditingController();
  final _directNote = TextEditingController();

  final _reqPayerId = TextEditingController();
  final _reqAmount = TextEditingController();
  final _reqNote = TextEditingController();

  final Map<String, String> _nameCache = {};

  bool _sendingDirect = false;
  bool _sendingReq = false;

  late Future<_HistoryBundle> _historyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _historyFuture = _loadHistory();
  }

  Future<void> _reloadHistory() async {
    final f = _loadHistory();
    setState(() {
      _historyFuture = f;
    });
    await f;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _directToId.dispose();
    _directAmount.dispose();
    _directNote.dispose();
    _reqPayerId.dispose();
    _reqAmount.dispose();
    _reqNote.dispose();
    super.dispose();
  }

  Future<String> _displayNameFor(String uid) async {
    if (_nameCache.containsKey(uid)) return _nameCache[uid]!;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = (doc.data()?['displayName'] as String?)?.trim();
      final label =
          (name != null && name.isNotEmpty) ? name : '${uid.substring(0, 8)}…';
      _nameCache[uid] = label;
      return label;
    } catch (_) {
      return '${uid.substring(0, 8)}…';
    }
  }

  int? _parseAmount(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 1 || n > 1000000) return null;
    return n;
  }

  String _friendlyError(TokenTransferResult r) {
    final code = r.errorCode ?? '';
    final msg = r.errorMessage ?? '';
    if (msg.contains('SELF_TRANSFER') || msg.contains('SELF_REQUEST')) {
      return 'Nu poți trimite sau solicita tokeni către propriul cont.';
    }
    if (msg.contains('INSUFFICIENT_BALANCE')) {
      return 'Sold insuficient în portofelul transferabil.';
    }
    if (msg.contains('WALLET_FROZEN')) return 'Portofelul este înghețat.';
    if (msg.contains('WALLET_CLOSED')) return 'Portofelul este închis.';
    if (msg.contains('COUNTERPARTY_NOT_FOUND') ||
        code == 'not-found') {
      return 'Utilizator negăsit sau fără portofel transferabil activ.';
    }
    if (msg.contains('REQUEST_EXPIRED')) return 'Cererea a expirat.';
    if (msg.contains('REQUEST_NOT_PENDING')) {
      return 'Cererea nu mai este în așteptare.';
    }
    if (msg.contains('INVALID_AMOUNT')) {
      return 'Suma trebuie să fie un număr întreg între 1 și 1.000.000.';
    }
    if (msg.isNotEmpty) return msg;
    return 'A apărut o eroare (${code.isNotEmpty ? code : 'necunoscută'}).';
  }

  Future<void> _submitDirect() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final rawTo = _directToId.text.trim();
    final amount = _parseAmount(_directAmount.text);
    if (rawTo.isEmpty) {
      _snack('Introdu numărul de telefon sau ID-ul destinatarului.');
      return;
    }
    if (amount == null) {
      _snack('Introdu o sumă validă (1–1.000.000).');
      return;
    }

    setState(() => _sendingDirect = true);
    final resolved = await _svc.resolveCounterpartyUserId(rawTo);
    if (!mounted) return;
    if (resolved.error != null) {
      setState(() => _sendingDirect = false);
      _snack(resolved.error!);
      return;
    }
    final toId = resolved.userId!;
    if (toId == uid) {
      setState(() => _sendingDirect = false);
      _snack('Nu poți transfera către propriul cont.');
      return;
    }

    final note = _directNote.text.trim();
    final result = await _svc.createDirectTransfer(
      toUserId: toId,
      amountMinor: amount,
      note: note.isEmpty ? null : note,
      clientRequestId: _uuid.v4(),
    );
    if (!mounted) return;
    setState(() => _sendingDirect = false);

    if (result.success) {
      _snack('Transfer reușit.', ok: true);
      _directAmount.clear();
      _directNote.clear();
    } else {
      _snack(_friendlyError(result));
    }
  }

  Future<void> _submitRequest() async {
    final rawPayer = _reqPayerId.text.trim();
    final amount = _parseAmount(_reqAmount.text);
    if (rawPayer.isEmpty) {
      _snack('Introdu numărul de telefon sau ID-ul plătitorului.');
      return;
    }
    if (amount == null) {
      _snack('Introdu o sumă validă (1–1.000.000).');
      return;
    }

    setState(() => _sendingReq = true);
    final resolved = await _svc.resolveCounterpartyUserId(rawPayer);
    if (!mounted) return;
    if (resolved.error != null) {
      setState(() => _sendingReq = false);
      _snack(resolved.error!);
      return;
    }
    final payerId = resolved.userId!;
    if (payerId == FirebaseAuth.instance.currentUser?.uid) {
      setState(() => _sendingReq = false);
      _snack('Nu poți crea o cerere către propriul cont.');
      return;
    }

    final note = _reqNote.text.trim();
    final result = await _svc.createPaymentRequest(
      payerId: payerId,
      amountMinor: amount,
      note: note.isEmpty ? null : note,
    );
    if (!mounted) return;
    setState(() => _sendingReq = false);

    if (result.success) {
      _snack('Cererea a fost trimisă.', ok: true);
      _reqAmount.clear();
      _reqNote.clear();
    } else {
      _snack(_friendlyError(result));
    }
  }

  void _snack(String text, {bool ok = false}) {
    if (ok) {
      AppFeedback.success(context, text);
    } else {
      AppFeedback.error(context, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM yyyy, HH:mm', 'ro');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer tokeni'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trimite'),
            Tab(text: 'Cereri'),
            Tab(text: 'Istoric'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(theme),
          _buildRequestsTab(theme, df),
          _buildHistoryTab(theme, df),
        ],
      ),
    );
  }

  Widget _buildSendTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<TokenWalletTransfer?>(
            stream: _svc.walletStream,
            builder: (context, snap) {
              final w = snap.data;
              final balance = w?.balanceMinor ?? 0;
              final frozen = w?.status != TokenWalletStatus.active;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.tertiary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Decorative background circles
                      Positioned(
                        right: -20,
                        top: -20,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'SOLD TRANSFERABIL',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_user_rounded, size: 14, color: Colors.cyan),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$balance',
                                        style: theme.textTheme.displaySmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Outfit',
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'tokeni',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (frozen)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '⚠️ Portofel restricționat',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (balance > 0)
                              TextButton(
                                onPressed: () {
                                  _directAmount.text = balance.toString();
                                  HapticFeedback.lightImpact();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  foregroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('MAX', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Transfer direct',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tokenii sunt trimiși imediat. Introdu numărul de telefon (cum e în profilul Nabour) '
            'sau ID-ul contului din Profil dacă telefonul nu găsește un singur utilizator.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _directToId,
            decoration: const InputDecoration(
              labelText: 'Telefon sau ID destinatar',
              hintText: 'ex. 0712345678 sau +40712345678',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_search_rounded),
            ),
            autocorrect: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _directAmount,
            decoration: const InputDecoration(
              labelText: 'Sumă (tokeni)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.toll_rounded),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _directNote,
            decoration: const InputDecoration(
              labelText: 'Notă (opțional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            maxLength: 200,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _sendingDirect ? null : _submitDirect,
            icon: _sendingDirect
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_sendingDirect ? 'Se trimite…' : 'Trimite transferul'),
          ),
          const SizedBox(height: 28),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),
          Text(
            'Cerere de plată',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Solicită tokeni de la alt utilizator. Introdu telefonul sau ID-ul Nabour; '
            'persoana primește cererea și poate accepta sau refuza.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reqPayerId,
            decoration: const InputDecoration(
              labelText: 'Telefon sau ID plătitor',
              hintText: 'ex. 0712345678',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.how_to_reg_rounded),
            ),
            autocorrect: false,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reqAmount,
            decoration: const InputDecoration(
              labelText: 'Sumă cerută (tokeni)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.request_quote_rounded),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reqNote,
            decoration: const InputDecoration(
              labelText: 'Notă (opțional)',
              border: OutlineInputBorder(),
            ),
            maxLength: 200,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _sendingReq ? null : _submitRequest,
            icon: _sendingReq
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mail_outline_rounded),
            label: Text(_sendingReq ? 'Se trimite…' : 'Trimite cererea'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(ThemeData theme, DateFormat df) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Autentificare necesară.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'De achitat de tine',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<TokenPaymentRequest>>(
            stream: _svc.pendingPayerRequestsStream,
            builder: (context, snap) {
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return Text(
                  'Nu ai cereri în așteptare ca plătitor.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              }
              return Column(
                children: list
                    .map((r) => _payerRequestCard(theme, df, r))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Trimise de tine (în așteptare)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<TokenPaymentRequest>>(
            stream: _svc.pendingPayeeRequestsStream,
            builder: (context, snap) {
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return Text(
                  'Nu ai cereri trimise în așteptare.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              }
              return Column(
                children: list
                    .map((r) => _payeeRequestCard(theme, df, r))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _payerRequestCard(
    ThemeData theme,
    DateFormat df,
    TokenPaymentRequest r,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: _displayNameFor(r.payeeId),
              builder: (context, snap) {
                final name = snap.data ?? '…';
                return Text(
                  'De la beneficiar: $name',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
            Text(
              '${r.amountMinor} tokeni · ${df.format(r.createdAt.toLocal())}',
              style: theme.textTheme.bodySmall,
            ),
            if (r.note != null && r.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('„${r.note}”', style: theme.textTheme.bodySmall),
              ),
            Text(
              'Expiră: ${df.format(r.expiresAt.toLocal())}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(r.requestId, accept: true),
                    child: const Text('Acceptă'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(r.requestId, accept: false),
                    child: const Text('Refuză'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _payeeRequestCard(
    ThemeData theme,
    DateFormat df,
    TokenPaymentRequest r,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: _displayNameFor(r.payerId),
              builder: (context, snap) {
                final name = snap.data ?? '…';
                return Text(
                  'Plătitor: $name',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
            Text(
              '${r.amountMinor} tokeni · ${df.format(r.createdAt.toLocal())}',
              style: theme.textTheme.bodySmall,
            ),
            if (r.note != null && r.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('„${r.note}”', style: theme.textTheme.bodySmall),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancelReq(r.requestId),
                child: const Text('Anulează cererea'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(String requestId, {required bool accept}) async {
    if (!accept) {
      final reason = await _promptDeclineReason();
      if (!mounted) return;
      if (reason == null) return;
      final res = await _svc.respondToPaymentRequest(
        requestId: requestId,
        action: 'decline',
        declineReason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      if (res.success) {
        _snack('Cerere refuzată.', ok: true);
      } else {
        _snack(_friendlyError(res));
      }
      return;
    }

    final res = await _svc.respondToPaymentRequest(
      requestId: requestId,
      action: 'accept',
    );
    if (!mounted) return;
    if (res.success) {
      _snack('Plată efectuată.', ok: true);
    } else {
      _snack(_friendlyError(res));
    }
  }

  Future<String?> _promptDeclineReason() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Motiv refuz (opțional)'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Lasă gol pentru fără motiv',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('Renunță'),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                controller.dispose();
                Navigator.pop(ctx, t);
              },
              child: const Text('Refuză'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelReq(String requestId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anulezi cererea?'),
        content: const Text(
          'Plătitorul nu va mai putea accepta această cerere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nu'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Da, anulează'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final res = await _svc.cancelPaymentRequest(requestId);
    if (!mounted) return;
    if (res.success) {
      _snack('Cerere anulată.', ok: true);
    } else {
      _snack(_friendlyError(res));
    }
  }

  Widget _buildHistoryTab(ThemeData theme, DateFormat df) {
    return FutureBuilder<_HistoryBundle>(
      future: _historyFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bundle = snap.data!;
        final transfers = bundle.transfers;
        final requests = bundle.requests;

        return RefreshIndicator(
          onRefresh: _reloadHistory,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Transferuri directe',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (transfers.isEmpty)
                Text(
                  'Niciun transfer încă.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              else
                ...transfers.map((t) {
                  final self = FirebaseAuth.instance.currentUser?.uid;
                  final outgoing = t.fromUserId == self;
                  final other = outgoing ? t.toUserId : t.fromUserId;
                  final arrow = outgoing ? '→' : '←';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        outgoing ? Icons.north_east_rounded : Icons.south_west_rounded,
                        color: outgoing ? Colors.teal : Colors.indigo,
                      ),
                      title: FutureBuilder<String>(
                        future: _displayNameFor(other),
                        builder: (context, ns) {
                          return Text(
                            '$arrow ${ns.data ?? '…'} · ${t.amountMinor} tokeni',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                      subtitle: Text(
                        '${df.format(t.createdAt.toLocal())} · '
                        '${t.status == DirectTransferStatus.completed ? 'Finalizat' : 'Eșuat'}',
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              Text(
                'Cereri de plată (rezolvate)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (requests.isEmpty)
                Text(
                  'Nicio cerere în istoric.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              else
                ...requests.map((r) {
                  final self = FirebaseAuth.instance.currentUser?.uid;
                  final label = r.payerId == self ? 'Plătitor' : 'Beneficiar';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.amber.shade800,
                      ),
                      title: Text(
                        '$label · ${r.amountMinor} tokeni · ${_statusRo(r.status)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(df.format(r.createdAt.toLocal())),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Future<_HistoryBundle> _loadHistory() async {
    final t = await _svc.getTransferHistory(limit: 40);
    final r = await _svc.getRequestHistory(limit: 40);
    return _HistoryBundle(transfers: t, requests: r);
  }

  String _statusRo(PaymentRequestStatus s) {
    switch (s) {
      case PaymentRequestStatus.pending:
        return 'În așteptare';
      case PaymentRequestStatus.accepted:
        return 'Acceptată';
      case PaymentRequestStatus.declined:
        return 'Refuzată';
      case PaymentRequestStatus.cancelled:
        return 'Anulată';
      case PaymentRequestStatus.expired:
        return 'Expirată';
    }
  }
}

class _HistoryBundle {
  final List<TokenDirectTransfer> transfers;
  final List<TokenPaymentRequest> requests;

  _HistoryBundle({required this.transfers, required this.requests});
}
