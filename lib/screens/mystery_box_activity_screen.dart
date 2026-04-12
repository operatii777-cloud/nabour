import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/features/mystery_box/community_mystery_box_service.dart';
import 'package:nabour_app/features/mystery_box/community_mystery_map_refresh.dart';
import 'package:nabour_app/features/mystery_box/mystery_box_activity_service.dart';
import 'package:nabour_app/models/token_wallet_model.dart';

/// Evidenta cutiilor plasate, deschise si a tokenilor asociati.
class MysteryBoxActivityScreen extends StatefulWidget {
  const MysteryBoxActivityScreen({super.key});

  @override
  State<MysteryBoxActivityScreen> createState() => _MysteryBoxActivityScreenState();
}

class _MysteryBoxActivityScreenState extends State<MysteryBoxActivityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _svc = MysteryBoxActivityService.instance;
  static final _df = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activitate cutii'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Rezumat'),
            Tab(text: 'Plasate'),
            Tab(text: 'Deschise de mine'),
            Tab(text: 'Deschideri la cutiile mele'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(svc: _svc, scheme: scheme),
          _PlacedTab(svc: _svc, df: _df),
          _MyOpensTab(svc: _svc, df: _df),
          _PlacerNotifsTab(svc: _svc, df: _df),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.svc,
    required this.scheme,
  });

  final MysteryBoxActivityService svc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Progres si recompense (estimari pe baza inregistrarilor din cont).',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<UserPlacedCommunityBox>>(
          stream: svc.placedCommunityBoxesStream(),
          builder: (context, placedSnap) {
            final placed = placedSnap.data ?? [];
            final active = placed.where((b) => b.status == 'active').length;
            final opened = placed.where((b) => b.status == 'claimed').length;
            final staked = placed.length * TokenCost.mysteryBoxSlot;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cutii pe harta (comunitate)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total plasate: ${placed.length}'),
                    Text('Active: $active'),
                    Text('Deschise de altcineva: $opened'),
                    const SizedBox(height: 4),
                    Text(
                      'Tokeni folositi la plasare (estimare): $staked',
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<UserCommunityBoxClaim>>(
          stream: svc.myCommunityClaimsStream(),
          builder: (context, commSnap) {
            final n = (commSnap.data ?? []).length;
            final earned = n * TokenCost.mysteryBoxSlot;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cutii comunitare deschise de tine',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('Numar deschideri: $n'),
                    Text(
                      'Tokeni primiti (estimare, ${TokenCost.mysteryBoxSlot}/cutie): $earned',
                      style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<UserOpenedBusinessMysteryBox>>(
          stream: svc.openedBusinessBoxesStream(),
          builder: (context, bizSnap) {
            final n = (bizSnap.data ?? []).length;
            final earned = n * TokenCost.mysteryBoxSlot;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cutii la oferte business',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('Inregistrari deschideri: $n'),
                    Text(
                      'Tokeni primiti (estimare, ${TokenCost.mysteryBoxSlot}/deschidere): $earned',
                      style: TextStyle(color: Colors.deepOrange.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<CommunityBoxPlacerNotification>>(
          stream: svc.placerNotificationsStream(),
          builder: (context, notifSnap) {
            final n = (notifSnap.data ?? []).length;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feedback plasator',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Notificari despre deschideri la cutiile tale: $n (in lista „Deschideri la cutiile mele”)',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PlacedTab extends StatefulWidget {
  const _PlacedTab({required this.svc, required this.df});

  final MysteryBoxActivityService svc;
  final DateFormat df;

  @override
  State<_PlacedTab> createState() => _PlacedTabState();
}

class _PlacedTabState extends State<_PlacedTab> {
  bool _bulkBusy = false;
  String? _busyBoxId;

  Future<void> _confirmRemoveAll(int activeCount) async {
    if (activeCount <= 0 || _bulkBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Retrag toate cutiile active'),
        content: Text(
          'Se retrag $activeCount cutii de pe hartă. Primești înapoi câte '
          '${TokenCost.mysteryBoxSlot} tokeni per cutie (garanție).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retrage tot'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _bulkBusy = true);
    try {
      final n =
          await CommunityMysteryBoxService.instance.removeAllActiveBoxes();
      CommunityMysteryMapRefresh.instance.notify();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              n == 0
                  ? 'Nu mai existau cutii active.'
                  : 'Retrase $n cutii. Tokenii au fost returnați.',
            ),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Eroare la retragere.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _confirmRemoveOne(UserPlacedCommunityBox b) async {
    if (b.status != 'active' || _busyBoxId != null || _bulkBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Retrage cutia de pe hartă'),
        content: Text(
          'Primești înapoi ${TokenCost.mysteryBoxSlot} tokeni (garanție). '
          'Cutia nu va mai fi vizibilă altor utilizatori.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retrage'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyBoxId = b.id);
    try {
      await CommunityMysteryBoxService.instance.removeActiveBox(b.id);
      CommunityMysteryMapRefresh.instance.notify();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cutia a fost retrasă de pe hartă.'),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Nu s-a putut retrage.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyBoxId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserPlacedCommunityBox>>(
      stream: widget.svc.placedCommunityBoxesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text('Nu ai plasat inca cutii comunitare pe harta.'),
          );
        }
        final active =
            list.where((b) => b.status == 'active').length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (active > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: FilledButton.tonalIcon(
                  onPressed: _bulkBusy ? null : () => _confirmRemoveAll(active),
                  icon: _bulkBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.inventory_2_outlined),
                  label: Text(
                    active == 1
                        ? 'Retrage cutia activă de pe hartă'
                        : 'Retrage toate cutiile active ($active)',
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final b = list[i];
                  final statusLabel = b.status == 'active'
                      ? 'Activă'
                      : b.status == 'claimed'
                          ? 'Deschisă'
                          : b.status;
                  final busy = _busyBoxId == b.id;
                  return Card(
                    child: ListTile(
                      title: Text(
                        b.message.trim().isEmpty
                            ? 'Cutie fara mesaj'
                            : b.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '$statusLabel · ${TokenCost.mysteryBoxSlot} tok recompensa\n'
                        '${b.createdAt != null ? widget.df.format(b.createdAt!.toLocal()) : "—"}',
                      ),
                      isThreeLine: true,
                      trailing: b.status == 'active'
                          ? IconButton(
                              tooltip: 'Retrage de pe hartă',
                              onPressed: busy || _bulkBusy
                                  ? null
                                  : () => _confirmRemoveOne(b),
                              icon: busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline_rounded),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MyOpensTab extends StatelessWidget {
  const _MyOpensTab({required this.svc, required this.df});

  final MysteryBoxActivityService svc;
  final DateFormat df;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserCommunityBoxClaim>>(
      stream: svc.myCommunityClaimsStream(),
      builder: (context, commSnap) {
        return StreamBuilder<List<UserOpenedBusinessMysteryBox>>(
          stream: svc.openedBusinessBoxesStream(),
          builder: (context, bizSnap) {
            if (commSnap.connectionState == ConnectionState.waiting &&
                bizSnap.connectionState == ConnectionState.waiting &&
                !commSnap.hasData &&
                !bizSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final comm = commSnap.data ?? [];
            final biz = bizSnap.data ?? [];
            if (comm.isEmpty && biz.isEmpty) {
              return const Center(
                child: Text('Nu ai inregistrari de deschideri inca.'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (comm.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Comunitate',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  ...comm.map(
                    (c) => Card(
                      child: ListTile(
                        title: Text(
                          c.message.trim().isEmpty ? 'Cutie comunitara' : c.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '+${c.rewardTokens} tok · ${c.claimedAt != null ? df.format(c.claimedAt!.toLocal()) : "—"}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (biz.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Business',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  ...biz.map(
                    (b) => Card(
                      child: ListTile(
                        title: Text(b.businessName.isEmpty ? 'Oferta' : b.businessName),
                        subtitle: Text(
                          'Cod: ${_maskCode(b.redemptionCode)} · ${b.openedAt != null ? df.format(b.openedAt!.toLocal()) : "—"}',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static String _maskCode(String code) {
    if (code.length <= 4) return '****';
    return '${code.substring(0, 2)}···${code.substring(code.length - 2)}';
  }
}

class _PlacerNotifsTab extends StatelessWidget {
  const _PlacerNotifsTab({required this.svc, required this.df});

  final MysteryBoxActivityService svc;
  final DateFormat df;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityBoxPlacerNotification>>(
      stream: svc.placerNotificationsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text('Nicio deschidere inregistrata la cutiile tale inca.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final n = list[i];
            final shortBox = n.boxId.length > 8
                ? '${n.boxId.substring(0, 8)}…'
                : n.boxId;
            return Card(
              child: ListTile(
                leading: Icon(Icons.notifications_active_rounded, color: Colors.teal.shade600),
                title: const Text('Cutia ta a fost deschisa'),
                subtitle: Text(
                  'Cutie $shortBox · deschizatorul a primit ${n.rewardTokens} tok\n'
                  '${n.createdAt != null ? df.format(n.createdAt!.toLocal()) : "—"}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
