import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/features/mystery_box/comm_mystery_box_service.dart';
import 'package:nabour_app/features/mystery_box/comm_mystery_map_refresh.dart';
import 'package:nabour_app/features/mystery_box/mystery_box_act_service.dart';
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

class _SummaryTab extends StatefulWidget {
  const _SummaryTab({
    required this.svc,
    required this.scheme,
  });

  final MysteryBoxActivityService svc;
  final ColorScheme scheme;

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
  bool _clearBusy = false;

  Future<void> _confirmClearSummary() async {
    if (_clearBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Curăță rezumatul din istoric'),
        content: const Text(
          'Se șterg notificările despre deschideri la cutiile tale, '
          'înregistrările la oferte business și se ascund din listă toate '
          'cutiile comunitare plasate sau deschise de tine. '
          'Tokenii deja câștigați sau folosiți nu se modifică.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Curăță'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _clearBusy = true);
    try {
      await widget.svc.clearSummaryActivityHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Istoricul din rezumat a fost curățat.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _clearBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    final scheme = widget.scheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Progres si recompense (estimari pe baza inregistrarilor din cont). '
          'Fiecare filă are și «Elimină tot din această filă», separat de rezumat.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _clearBusy ? null : _confirmClearSummary,
          icon: _clearBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cleaning_services_outlined),
          label: const Text('Curăță tot ce intră în rezumat (toate sursele)'),
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
  bool _clearEntireTabBusy = false;
  String? _busyBoxId;

  bool get _placedGlobalBusy =>
      _bulkBusy || _busyBoxId != null || _clearEntireTabBusy;

  Future<void> _confirmClearEntirePlacedTab() async {
    if (_placedGlobalBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimină tot din această filă'),
        content: Text(
          'Se retrag toate cutiile încă active de pe hartă (cu câte '
          '${TokenCost.mysteryBoxSlot} tokeni înapoi per cutie), apoi dispar '
          'din listă toate rândurile (inclusiv cele deja deschise sau anulate).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimină tot'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _clearEntireTabBusy = true);
    try {
      await widget.svc.clearEntirePlacedTabActivity();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista „Plasate” a fost golită (cutiile active au fost retrase).'),
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
      if (mounted) setState(() => _clearEntireTabBusy = false);
    }
  }

  Future<void> _confirmRemoveAll(int activeCount) async {
    if (activeCount <= 0 || _bulkBusy || _clearEntireTabBusy) return;
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
    if (b.status != 'active' || _busyBoxId != null || _bulkBusy || _clearEntireTabBusy) {
      return;
    }
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

  Future<void> _confirmHideFromActivity(UserPlacedCommunityBox b) async {
    if (b.status == 'active' || _busyBoxId != null || _bulkBusy || _clearEntireTabBusy) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimină din listă'),
        content: const Text(
          'Rândul dispare din „Plasate” și din rezumat. Cutia rămâne înregistrată '
          'în sistem; nu se schimbă tokenii.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimină'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyBoxId = b.id);
    try {
      await widget.svc.hidePlacedBoxFromActivity(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminat din listă.')),
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
                  onPressed: _bulkBusy || _clearEntireTabBusy
                      ? null
                      : () => _confirmRemoveAll(active),
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
            Padding(
              padding: EdgeInsets.fromLTRB(12, active > 0 ? 8 : 8, 12, 0),
              child: FilledButton.tonalIcon(
                onPressed: _placedGlobalBusy ? null : _confirmClearEntirePlacedTab,
                icon: _clearEntireTabBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_remove_rounded),
                label: const Text('Elimină tot din această filă'),
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
                              onPressed: busy || _placedGlobalBusy
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
                          : IconButton(
                              tooltip: 'Elimină din listă',
                              onPressed: busy || _placedGlobalBusy
                                  ? null
                                  : () => _confirmHideFromActivity(b),
                              icon: busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline_rounded),
                            ),
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

class _MyOpensTab extends StatefulWidget {
  const _MyOpensTab({required this.svc, required this.df});

  final MysteryBoxActivityService svc;
  final DateFormat df;

  @override
  State<_MyOpensTab> createState() => _MyOpensTabState();
}

class _MyOpensTabState extends State<_MyOpensTab> {
  /// `c:` + boxId sau `b:` + docId business
  String? _busyKey;
  bool _clearEntireTabBusy = false;

  bool get _opensGlobalBusy => _busyKey != null || _clearEntireTabBusy;

  Future<void> _confirmClearEntireMyOpensTab() async {
    if (_opensGlobalBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimină tot din această filă'),
        content: const Text(
          'Se ascund toate deschiderile la cutii comunitare din listă și se șterg '
          'toate înregistrările la oferte business din această filă. Tokenii nu se modifică.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimină tot'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _clearEntireTabBusy = true);
    try {
      await widget.svc.clearEntireMyOpensTabActivity();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista „Deschise de mine” a fost golită.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _clearEntireTabBusy = false);
    }
  }

  Future<void> _confirmRemoveCommunity(UserCommunityBoxClaim c) async {
    if (_busyKey != null || _clearEntireTabBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimină din listă'),
        content: const Text(
          'Rândul dispare din „Deschise de mine”. Deschiderea rămâne înregistrată în sistem; tokenii nu se modifică.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimină'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyKey = 'c:${c.boxId}');
    try {
      await widget.svc.hideCommunityClaimFromActivity(c.boxId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminat din listă.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _confirmRemoveBusiness(UserOpenedBusinessMysteryBox b) async {
    if (_busyKey != null || _clearEntireTabBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge înregistrarea'),
        content: const Text(
          'Se șterge această înregistrare din cont. Oferta în sine nu este anulată.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyKey = 'b:${b.id}');
    try {
      await widget.svc.deleteOpenedBusinessRecord(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Înregistrarea a fost ștearsă.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  String _maskCode(String code) {
    if (code.length <= 4) return '****';
    return '${code.substring(0, 2)}···${code.substring(code.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final df = widget.df;
    return StreamBuilder<List<UserCommunityBoxClaim>>(
      stream: widget.svc.myCommunityClaimsStream(),
      builder: (context, commSnap) {
        return StreamBuilder<List<UserOpenedBusinessMysteryBox>>(
          stream: widget.svc.openedBusinessBoxesStream(),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: FilledButton.tonalIcon(
                    onPressed: _opensGlobalBusy ? null : _confirmClearEntireMyOpensTab,
                    icon: _clearEntireTabBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.playlist_remove_rounded),
                    label: const Text('Elimină tot din această filă'),
                  ),
                ),
                Expanded(
                  child: ListView(
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
                    (c) {
                      final busy = _busyKey == 'c:${c.boxId}';
                      return Card(
                        child: ListTile(
                          title: Text(
                            c.message.trim().isEmpty ? 'Cutie comunitara' : c.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '+${c.rewardTokens} tok · ${c.claimedAt != null ? df.format(c.claimedAt!.toLocal()) : "—"}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Elimină din listă',
                            onPressed: busy || _opensGlobalBusy
                                ? null
                                : () => _confirmRemoveCommunity(c),
                            icon: busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      );
                    },
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
                    (b) {
                      final busy = _busyKey == 'b:${b.id}';
                      return Card(
                        child: ListTile(
                          title: Text(b.businessName.isEmpty ? 'Oferta' : b.businessName),
                          subtitle: Text(
                            'Cod: ${_maskCode(b.redemptionCode)} · ${b.openedAt != null ? df.format(b.openedAt!.toLocal()) : "—"}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Șterge înregistrarea',
                            onPressed: busy || _opensGlobalBusy
                                ? null
                                : () => _confirmRemoveBusiness(b),
                            icon: busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PlacerNotifsTab extends StatefulWidget {
  const _PlacerNotifsTab({required this.svc, required this.df});

  final MysteryBoxActivityService svc;
  final DateFormat df;

  @override
  State<_PlacerNotifsTab> createState() => _PlacerNotifsTabState();
}

class _PlacerNotifsTabState extends State<_PlacerNotifsTab> {
  String? _busyNotifId;
  bool _clearEntireTabBusy = false;

  bool get _notifsGlobalBusy => _busyNotifId != null || _clearEntireTabBusy;

  String _openerLabel(CommunityBoxPlacerNotification n) {
    final name = n.openerName.trim();
    if (name.isNotEmpty) return name;
    if (n.openerUid.length >= 8) return n.openerUid.substring(0, 8);
    if (n.openerUid.isNotEmpty) return n.openerUid;
    return 'un utilizator';
  }

  Future<void> _confirmClearEntireNotifsTab() async {
    if (_notifsGlobalBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimină tot din această filă'),
        content: const Text(
          'Se șterg toate notificările despre deschideri la cutiile tale. '
          'Cutiile și tokenii rămân neschimbate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimină tot'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _clearEntireTabBusy = true);
    try {
      await widget.svc.clearAllPlacerNotificationsActivity();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toate notificările au fost șterse.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _clearEntireTabBusy = false);
    }
  }

  Future<void> _confirmDelete(CommunityBoxPlacerNotification n) async {
    if (_busyNotifId != null || _clearEntireTabBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge notificarea'),
        content: const Text(
          'Notificarea dispare din listă. Cutia și tokenii rămân neschimbate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyNotifId = n.id);
    try {
      await widget.svc.deletePlacerNotification(n.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificare ștearsă.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyNotifId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = widget.df;
    return StreamBuilder<List<CommunityBoxPlacerNotification>>(
      stream: widget.svc.placerNotificationsStream(),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: FilledButton.tonalIcon(
                onPressed: _notifsGlobalBusy ? null : _confirmClearEntireNotifsTab,
                icon: _clearEntireTabBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_remove_rounded),
                label: const Text('Elimină tot din această filă'),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final n = list[i];
                  final shortBox = n.boxId.length > 8
                      ? '${n.boxId.substring(0, 8)}…'
                      : n.boxId;
                  final opener = _openerLabel(n);
                  final busy = _busyNotifId == n.id;
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.notifications_active_rounded, color: Colors.teal.shade600),
                      title: Text('Cutia ta a fost deschisa de $opener'),
                      subtitle: Text(
                        'Cutie $shortBox · deschizatorul a primit ${n.rewardTokens} tok\n'
                        '${n.createdAt != null ? df.format(n.createdAt!.toLocal()) : "—"}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Șterge notificarea',
                        onPressed: busy || _notifsGlobalBusy
                            ? null
                            : () => _confirmDelete(n),
                        icon: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                      ),
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
