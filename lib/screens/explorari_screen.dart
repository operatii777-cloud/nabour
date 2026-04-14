import 'package:flutter/material.dart';
import 'package:nabour_app/features/explorari/explorari_firestore_sync.dart';
import 'package:nabour_app/features/explorari/explorari_service.dart';
import 'package:nabour_app/screens/explorari_ldrboard_screen.dart';
import 'package:nabour_app/services/explorari_home_bridge.dart';

/// Rezumat Explorări: zone locale, sync Firebase, widget Android.
class ExplorariScreen extends StatefulWidget {
  const ExplorariScreen({super.key});

  @override
  State<ExplorariScreen> createState() => _ExplorariScreenState();
}

class _ExplorariScreenState extends State<ExplorariScreen> {
  int _tiles = 0;
  double _pct = 0;
  bool _loading = true;
  bool _merging = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final n = await ExplorariService.instance.discoveredTileCount();
    final p = await ExplorariService.instance.explorationPercent();
    if (!mounted) return;
    setState(() {
      _tiles = n;
      _pct = p;
      _loading = false;
    });
    await updateExplorariHomeWidget(
      tileCount: n,
      percentRounded: p.round().clamp(0, 100),
    );
  }

  Future<void> _mergeFromCloud() async {
    setState(() => _merging = true);
    final added = await ExplorariFirestoreSync.instance
        .mergeRemoteIntoLocal(ExplorariService.instance.insertTileIdIfMissing);
    if (!mounted) return;
    setState(() => _merging = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0
              ? 'Am adăugat $added zone din cont.'
              : 'Nu sunt zone noi în cont sau le ai deja local.',
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorări'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Zone explorate',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Zonele se salvează local și se sincronizează în cont (Firestore). '
                  'Pe Android poți adăuga widget-ul „Nabour · Explorări” din lista de widget-uri.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final narrow = c.maxWidth < 340;
                    final mergeBtn = OutlinedButton.icon(
                      onPressed: _merging ? null : _mergeFromCloud,
                      icon: _merging
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_download_rounded),
                      label: const Text('Descarcă din cont'),
                    );
                    final rankBtn = FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExplorariLeaderboardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emoji_events_rounded),
                      label: const Text('Clasament'),
                    );
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          mergeBtn,
                          const SizedBox(height: 8),
                          rankBtn,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: mergeBtn),
                        const SizedBox(width: 8),
                        Expanded(child: rankBtn),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: (_pct / 100).clamp(0, 1),
                            strokeWidth: 10,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_pct.toStringAsFixed(0)}%',
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'țintă simbolică',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.grid_on_rounded),
                    title: const Text('Zone unice (local)'),
                    trailing: Text(
                      '$_tiles',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
