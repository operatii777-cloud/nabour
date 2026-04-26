import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/firestore_error_ui.dart';

/// Admin dashboard — statistici globale pentru operatorii Nabour.
/// Accesibil doar pentru userii cu role == 'admin'.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Utilizatori'),
            Tab(text: 'Tokeni'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _UsersTab(),
          _TokenStatsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Statistici utilizatori
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          Logger.error(
            'AdminDashboard users stream',
            error: snap.error,
            tag: 'AdminDashboard',
          );
          return FirestoreStreamErrorCenter(
            error: snap.error,
            fallbackMessage: 'Nu s-au putut încărca lista de utilizatori.',
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        final drivers = docs.where((d) => (d.data() as Map)['role'] == 'driver').length;
        final passengers = docs.length - drivers;

        return Column(
          children: [
            _StatRow(items: [
              _StatItem(label: 'Total useri', value: '${docs.length}', color: const Color(0xFF7C3AED)),
              _StatItem(label: 'Șoferi', value: '$drivers', color: Colors.green),
              _StatItem(label: 'Pasageri', value: '$passengers', color: Colors.blue),
            ]),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    leading: Text(d['avatar'] as String? ?? '🙂',
                        style: const TextStyle(fontSize: 22)),
                    title: Text(d['displayName'] as String? ?? '—',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                    subtitle: Text(d['email'] as String? ?? '—',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                    trailing: d['role'] == 'driver'
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text('Șofer',
                                style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
                          )
                        : null,
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Statistici tokeni
// ─────────────────────────────────────────────────────────────────────────────

class _TokenStatsTab extends StatefulWidget {
  const _TokenStatsTab();

  @override
  State<_TokenStatsTab> createState() => _TokenStatsTabState();
}

class _TokenStatsTabState extends State<_TokenStatsTab> {
  _AggregateStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Citim wallet-urile din subcollecțiile users/{uid}/token_wallet/wallet
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .limit(500)
          .get();

      int totalBalance = 0;
      int totalSpent = 0;
      int totalEarned = 0;
      final planCounts = <String, int>{};
      int usersWithWallet = 0;

      for (final userDoc in usersSnap.docs) {
        final walletSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('token_wallet')
            .doc('wallet')
            .get();

        if (!walletSnap.exists) continue;
        usersWithWallet++;

        final data = walletSnap.data()!;
        totalBalance += (data['balance'] as num?)?.toInt() ?? 0;
        totalSpent   += (data['totalSpent'] as num?)?.toInt() ?? 0;
        totalEarned  += (data['totalEarned'] as num?)?.toInt() ?? 0;

        final plan = data['plan'] as String? ?? 'free';
        planCounts[plan] = (planCounts[plan] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _stats = _AggregateStats(
            totalUsers: usersSnap.docs.length,
            usersWithWallet: usersWithWallet,
            totalBalance: totalBalance,
            totalSpent: totalSpent,
            totalEarned: totalEarned,
            planCounts: planCounts,
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final s = _stats;
    if (s == null) {
      return const Center(child: Text('Eroare la încărcarea statisticilor.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatRow(items: [
          _StatItem(label: 'Total tokeni sold', value: '${s.totalBalance}', color: const Color(0xFF7C3AED)),
          _StatItem(label: 'Total consumați', value: '${s.totalSpent}', color: Colors.red.shade400),
          _StatItem(label: 'Total emiși', value: '${s.totalEarned}', color: Colors.green),
        ]),
        const SizedBox(height: 16),
        const Text('Distribuție planuri',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        ...TokenPlan.values.map((plan) {
          final count = s.planCounts[plan.name] ?? 0;
          final pct = s.usersWithWallet > 0
              ? (count / s.usersWithWallet * 100).toStringAsFixed(1)
              : '0';
          return _PlanRow(plan: plan, count: count, pct: pct);
        }),
        const SizedBox(height: 16),
        _StatRow(items: [
          _StatItem(
            label: 'Useri cu wallet',
            value: '${s.usersWithWallet} / ${s.totalUsers}',
            color: Colors.blue,
          ),
          _StatItem(
            label: 'Medie sold/user',
            value: s.usersWithWallet > 0
                ? (s.totalBalance / s.usersWithWallet).toStringAsFixed(0)
                : '0',
            color: Colors.orange,
          ),
        ]),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _loading = true);
            _loadStats();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reîncarcă statisticile'),
        ),
      ],
    );
  }
}

class _AggregateStats {
  final int totalUsers;
  final int usersWithWallet;
  final int totalBalance;
  final int totalSpent;
  final int totalEarned;
  final Map<String, int> planCounts;

  const _AggregateStats({
    required this.totalUsers,
    required this.usersWithWallet,
    required this.totalBalance,
    required this.totalSpent,
    required this.totalEarned,
    required this.planCounts,
  });
}

class _PlanRow extends StatelessWidget {
  final TokenPlan plan;
  final int count;
  final String pct;

  const _PlanRow({required this.plan, required this.count, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(plan.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count > 0 ? double.tryParse(pct)! / 100 : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count ($pct%)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliare
// ─────────────────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final List<_StatItem> items;
  const _StatRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: items
            .map((item) => Expanded(child: _StatCard(item: item)))
            .toList(),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Text(item.value,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: item.color)),
          const SizedBox(height: 2),
          Text(item.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
