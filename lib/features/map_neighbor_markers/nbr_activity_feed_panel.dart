import 'package:flutter/material.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_dismiss_store.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_activity_deriver.dart';
import 'package:nabour_app/features/map_neighbor_markers/nbr_map_feed_controller.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';

/// Sertar inferior tip Bump: activitate recentă a prietenilor pe hartă.
class NeighborActivityFeedPanel extends StatefulWidget {
  const NeighborActivityFeedPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<NeighborActivityFeedPanel> createState() =>
      _NeighborActivityFeedPanelState();
}

class _NeighborActivityFeedPanelState extends State<NeighborActivityFeedPanel> {
  final NeighborActivityDeriver _deriver = NeighborActivityDeriver();
  Set<String> _dismissedRowIds = {};

  @override
  void initState() {
    super.initState();
    ActivityFeedDismissStore.loadMapFeedDismissed().then((s) {
      if (mounted) setState(() => _dismissedRowIds = s);
    });
  }

  Future<void> _dismissRow(String rowId) async {
    await ActivityFeedDismissStore.dismissMapFeedRow(rowId);
    if (!mounted) return;
    setState(() => _dismissedRowIds = {..._dismissedRowIds, rowId});
  }

  Future<void> _confirmDismissAll(List<NeighborActivityRow> visible) async {
    if (visible.isEmpty) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ștergi toate liniile?'),
        content: Text(
          'Se ascund ${visible.length} ${visible.length == 1 ? 'linie' : 'linii'} din Activitate pe hartă (pe acest dispozitiv).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge tot'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final ids = visible.map((r) => r.id).toList();
    await ActivityFeedDismissStore.dismissAllMapFeed(ids);
    if (!mounted) return;
    setState(() => _dismissedRowIds = {..._dismissedRowIds, ...ids});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NeighborLocation>>(
      valueListenable: NeighborMapFeedController.instance.neighbors,
      builder: (context, list, _) {
        if (list.isEmpty) return const SizedBox.shrink();

        final rows = _deriver.derive(list);
        final seen = <String>{};
        final displayRows = <NeighborActivityRow>[];
        for (final r in rows) {
          if (seen.add(r.id)) displayRows.add(r);
        }
        if (displayRows.length > 28) {
          displayRows.removeRange(28, displayRows.length);
        }
        final visibleRows = displayRows
            .where((r) => !_dismissedRowIds.contains(r.id))
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.11,
          minChildSize: 0.09,
          maxChildSize: 0.52,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            size: 20, color: Colors.deepPurple.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Activitate',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ),
                        Text(
                          '${list.length} pe hartă',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Șterge tot din listă',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: visibleRows.isEmpty
                              ? null
                              : () => _confirmDismissAll(visibleRows),
                          icon: Icon(
                            Icons.delete_sweep_rounded,
                            size: 22,
                            color: visibleRows.isEmpty
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (widget.onClose != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            tooltip: 'Închide',
                            icon: Icon(Icons.close_rounded,
                                size: 22, color: Colors.grey.shade700),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: visibleRows.length,
                      itemBuilder: (context, i) {
                        final row = visibleRows[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                  border: Border.all(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    row.avatar,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  row.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.25,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Șterge',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () => _dismissRow(row.id),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
