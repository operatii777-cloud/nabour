import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/models/subscription_plan_doc.dart';
import 'package:nabour_app/models/token_economy.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/subscription_catalog_service.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Trebuie să coincidă cu lista din parametrul Functions `STAFF_SUBSCRIPTION_EMAILS`.
const Set<String> kStaffSubscriptionEmails = {'operatii.777@gmail.com'};

/// Ecranul de cumpărare tokeni și upgrade plan.
///
/// Afișează:
///   - Planurile disponibile (Free / Basic / Pro / Unlimited)
///   - Pachete de tokeni suplimentari (top-up)
///   - Butoane de plată (Netopia, Stripe, Revolut Pay)
///   - Istoricul tranzacțiilor
class TokenShopScreen extends StatefulWidget {
  const TokenShopScreen({super.key});

  @override
  State<TokenShopScreen> createState() => _TokenShopScreenState();
}

class _TokenShopScreenState extends State<TokenShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const accent = AppColors.violetAccent;
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    final isStaff = email != null && kStaffSubscriptionEmails.contains(email);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tokenShopTitle),
        centerTitle: true,
        actions: [
          if (isStaff)
            IconButton(
              tooltip: l10n.tokenShopStaffMenuTooltip,
              icon: const Icon(Icons.verified_user_outlined),
              onPressed: () => _showStaffSubscriptionPicker(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.45),
          tabs: [
            Tab(text: l10n.tokenShopTabPlans),
            Tab(text: l10n.tokenShopTabTopup),
            Tab(text: l10n.tokenShopTabHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _PlansTab(),
          _TopupTab(),
          _HistoryTab(),
        ],
      ),
    );
  }

  Future<void> _showStaffSubscriptionPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDialog<TokenPlan>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tokenShopStaffDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TokenPlan.values
              .map(
                (p) => ListTile(
                  title: Text(_tokenPlanDisplayName(p, l10n)),
                  onTap: () => Navigator.pop(ctx, p),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    try {
      await TokenService().applyStaffSubscription(picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tokenShopStaffApplied)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Planuri de abonament
// ─────────────────────────────────────────────────────────────────────────────

class _PlansTab extends StatelessWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<SubscriptionPlanDoc>>(
      stream: SubscriptionCatalogService.instance.plansStream,
      builder: (context, catalogSnap) {
        final catalog = (catalogSnap.data != null && catalogSnap.data!.isNotEmpty)
            ? catalogSnap.data!
            : SubscriptionCatalogService.instance.defaultPlanDocs();

        return StreamBuilder<TokenWallet?>(
          stream: TokenService().walletStream,
          builder: (context, snap) {
            final currentPlan = snap.data?.plan ?? TokenPlan.free;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(
                  icon: Icons.workspace_premium_rounded,
                  title: l10n.tokenShopChoosePlanTitle,
                  subtitle: l10n.tokenShopChoosePlanSubtitle,
                ),
                const SizedBox(height: 12),
                ...catalog.expand((doc) {
                  final plan = doc.tokenPlan;
                  if (plan == null) return const Iterable<Widget>.empty();
                  return [
                    _PlanCard(
                      plan: plan,
                      monthlyAllowance: doc.monthlyAllowance,
                      isCurrent: plan == currentPlan,
                      onSelect: () => _selectPlan(context, plan, currentPlan),
                    ),
                  ];
                }),
                const SizedBox(height: 24),
                _PaymentMethodsNote(),
              ],
            );
          },
        );
      },
    );
  }

  void _selectPlan(BuildContext context, TokenPlan plan, TokenPlan current) {
    final l10n = AppLocalizations.of(context)!;
    if (plan == current) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tokenShopAlreadyOnPlan)),
      );
      return;
    }
    if (plan == TokenPlan.free) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tokenShopDowngradeContactSupport)),
      );
      return;
    }
    final planName = _tokenPlanDisplayName(plan, l10n);
    final price = _tokenPlanPriceLabel(plan, l10n);
    _showPaymentDialog(context, planName, price, () async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      try {
        await TokenService().upgradePlan(uid, plan);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.tokenShopUpgradeSuccess(planName)),
            ),
          );
        }
      } on FirebaseFunctionsException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'failed-precondition'
                  ? l10n.tokenShopErrorPaymentsNotReady
                  : l10n.tokenShopErrorWithMessage(e.message ?? e.code),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tokenShopUpgradeError(e.toString())),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    });
  }
}

class _PlanCard extends StatelessWidget {
  final TokenPlan plan;
  final int monthlyAllowance;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.monthlyAllowance,
    required this.isCurrent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final surface = theme.colorScheme.surface;
    const violet = AppColors.violetAccent;
    final planName = _tokenPlanDisplayName(plan, l10n);
    final price = _tokenPlanPriceLabel(plan, l10n);
    final allowanceStr = monthlyAllowance >= 999999998
        ? '∞'
        : '$monthlyAllowance';
    final allowanceLine = l10n.tokenShopPlanAllowanceMonthly(allowanceStr);
    final economy = TokenEconomySummary.fromMonthlyAllowance(monthlyAllowance);
    final isPopular = plan == TokenPlan.basic;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? violet
              : isPopular
                  ? violet.withValues(alpha: 0.4)
                  : theme.dividerColor.withValues(alpha: 0.35),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular && !isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: const BoxDecoration(
                color: violet,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Text(
                l10n.tokenShopMostPopular,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Iconiță plan
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: violet.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_planIcon(plan), color: violet, size: 22),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        allowanceLine,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      if (economy.isUnlimited)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.tokenShopEconomyUnlimited,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.25,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.48),
                            ),
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.tokenShopEconomyApproxLine(
                              economy.aiQueries,
                              economy.routeCalcs,
                              economy.geocodings,
                              economy.broadcastPosts,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.25,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.48),
                            ),
                          ),
                        ),
                        Text(
                          l10n.tokenShopEconomyBusinessLine(
                            economy.businessOffers,
                            TokenCost.businessOffer,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.25,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Preț + buton
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: violet,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          l10n.tokenShopActive,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700),
                        ),
                      )
                    else if (plan != TokenPlan.free)
                      TextButton(
                        onPressed: onSelect,
                        style: TextButton.styleFrom(
                          backgroundColor: violet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          l10n.tokenShopSelect,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _planIcon(TokenPlan plan) {
    switch (plan) {
      case TokenPlan.free:      return Icons.volunteer_activism_rounded;
      case TokenPlan.basic:     return Icons.bolt_rounded;
      case TokenPlan.pro:       return Icons.rocket_launch_rounded;
      case TokenPlan.unlimited: return Icons.all_inclusive_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Top-up (cumpărare pachete de tokeni)
// ─────────────────────────────────────────────────────────────────────────────

class _TopupTab extends StatelessWidget {
  const _TopupTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final packages = _topupPackages(l10n);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          icon: Icons.add_circle_outline_rounded,
          title: l10n.tokenShopBuyExtraTitle,
          subtitle: l10n.tokenShopBuyExtraSubtitle,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: packages
              .map((p) => _TopupCard(
                    package: p,
                    onBuy: () => _buyPackage(context, p),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        _PaymentMethodsNote(),
      ],
    );
  }

  void _buyPackage(BuildContext context, _TopupPackage pkg) {
    final l10n = AppLocalizations.of(context)!;
    _showPaymentDialog(
      context,
      '${pkg.tokens} ${l10n.tokenShopTokensWord} (${pkg.label})',
      pkg.price,
      () async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        try {
          await TokenService().addTokens(
            uid,
            pkg.tokens,
            TokenTransactionType.purchase,
            description: l10n.tokenShopTxPurchasePackage(pkg.label, pkg.tokens),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.tokenShopTokensAdded(pkg.tokens)),
                backgroundColor: Colors.green,
              ),
            );
          }
        } on FirebaseFunctionsException catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.code == 'failed-precondition'
                    ? l10n.tokenShopTopupRequiresBackend
                    : l10n.tokenShopErrorWithMessage(e.message ?? e.code),
              ),
              backgroundColor: Colors.red.shade800,
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.tokenShopErrorWithMessage(e.toString())),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      },
    );
  }
}

class _TopupPackage {
  final int tokens;
  final String price;
  final String label;
  final bool popular;
  const _TopupPackage({
    required this.tokens,
    required this.price,
    required this.label,
    this.popular = false,
  });
}

class _TopupCard extends StatelessWidget {
  final _TopupPackage package;
  final VoidCallback onBuy;

  const _TopupCard({required this.package, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    const violet = AppColors.violetAccent;
    final surface = theme.colorScheme.surface;
    return InkWell(
      onTap: onBuy,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: package.popular ? violet : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: package.popular
                ? violet
                : theme.dividerColor.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (package.popular)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.tokenShopPopularBadge,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              '${package.tokens}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: package.popular
                    ? Colors.white
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              l10n.tokenShopTokensWord,
              style: TextStyle(
                fontSize: 12,
                color: package.popular
                    ? Colors.white70
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const Spacer(),
            Text(
              package.price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: package.popular ? Colors.white : violet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Istoric tranzacții
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<TokenTransaction>? _transactions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txs = await TokenService().getTransactionHistory(limit: 50);
    if (mounted) setState(() => _transactions = txs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    if (_transactions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions!.isEmpty) {
      return Center(
        child: Text(
          l10n.tokenShopNoTransactions,
          style: TextStyle(color: muted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _transactions!.length,
      itemBuilder: (_, i) => _TxTile(tx: _transactions![i]),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TokenTransaction tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.amount > 0;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isPositive
            ? Colors.green.shade50
            : Colors.red.shade50,
        child: Icon(
          isPositive ? Icons.add_rounded : Icons.remove_rounded,
          color: isPositive ? Colors.green.shade600 : Colors.red.shade500,
          size: 16,
        ),
      ),
      title: Text(
        tx.description,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _formatDate(tx.createdAt),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      trailing: Text(
        '${isPositive ? '+' : ''}${tx.amount}',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 15,
          color: isPositive ? Colors.green.shade600 : Colors.red.shade500,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget metode de plată
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tokenShopPaymentMethodsTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _PayBadge(label: 'Netopia', color: Colors.blue.shade700),
              _PayBadge(label: 'Stripe', color: Colors.indigo.shade600),
              _PayBadge(label: 'Revolut Pay', color: Colors.teal.shade600),
              _PayBadge(label: 'Card Visa/MC', color: Colors.grey.shade700),
              const _PayBadge(label: 'Apple Pay', color: Colors.black87),
              _PayBadge(label: 'Google Pay', color: Colors.green.shade700),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tokenShopPaymentSecureFooter,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PayBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dialog de plată simulat (placeholder până la integrarea SDK-urilor).
void _showPaymentDialog(
  BuildContext context,
  String product,
  String price,
  Future<void> Function() onConfirm,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PaymentSheet(
      product: product,
      price: price,
      onConfirm: onConfirm,
    ),
  );
}

class _PaymentSheet extends StatefulWidget {
  final String product;
  final String price;
  final Future<void> Function() onConfirm;

  const _PaymentSheet({
    required this.product,
    required this.price,
    required this.onConfirm,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  int _selectedMethod = 0;
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final methods = [
      l10n.tokenShopMethodNetopia,
      l10n.tokenShopMethodStripe,
      l10n.tokenShopMethodRevolut,
    ];
    const violet = AppColors.violetAccent;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.product,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(
            widget.price,
            style: const TextStyle(
              color: violet,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.tokenShopPaymentMethodTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: _selectedMethod,
            onChanged: (v) => setState(() => _selectedMethod = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: methods.asMap().entries.map((e) => RadioListTile<int>(
                value: e.key,
                title: Text(e.value, style: const TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.construction_rounded,
                    size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.tokenShopTestModeDisclaimer,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processing
                  ? null
                  : () async {
                      setState(() => _processing = true);
                      await widget.onConfirm();
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      l10n.tokenShopPay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _tokenPlanDisplayName(TokenPlan plan, AppLocalizations l10n) {
  switch (plan) {
    case TokenPlan.free:
      return l10n.tokenPlanFreeName;
    case TokenPlan.basic:
      return l10n.tokenPlanBasicName;
    case TokenPlan.pro:
      return l10n.tokenPlanProName;
    case TokenPlan.unlimited:
      return l10n.tokenPlanUnlimitedName;
  }
}

String _tokenPlanPriceLabel(TokenPlan plan, AppLocalizations l10n) {
  switch (plan) {
    case TokenPlan.free:
      return l10n.tokenPlanPriceFree;
    case TokenPlan.basic:
      return l10n.tokenPlanPriceBasic;
    case TokenPlan.pro:
      return l10n.tokenPlanPricePro;
    case TokenPlan.unlimited:
      return l10n.tokenPlanPriceUnlimited;
  }
}

List<_TopupPackage> _topupPackages(AppLocalizations l10n) => [
      _TopupPackage(
        tokens: 500,
        price: '2,99 RON',
        label: l10n.tokenShopPackageStarter,
      ),
      _TopupPackage(
        tokens: 1500,
        price: '7,99 RON',
        label: l10n.tokenShopPackagePopular,
        popular: true,
      ),
      _TopupPackage(
        tokens: 5000,
        price: '19,99 RON',
        label: l10n.tokenShopPackageAdvanced,
      ),
      _TopupPackage(
        tokens: 15000,
        price: '49,99 RON',
        label: l10n.tokenShopPackageBusiness,
      ),
    ];
