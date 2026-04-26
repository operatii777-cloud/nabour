import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/models/subscription_plan_doc.dart';
import 'package:nabour_app/models/token_economy.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/subscr_catalog_service.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/core/ui/app_feedback.dart';
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
                  title: Text(
                    _tokenPlanDisplayName(p, l10n),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
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
        AppFeedback.success(context, l10n.tokenShopStaffApplied);
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.error(context, '$e');
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Planuri de abonament
// ─────────────────────────────────────────────────────────────────────────────

const Map<TokenPlan, int> kPlanTokenPrices = {
  TokenPlan.basic: 1000,
  TokenPlan.pro: 5000,
  TokenPlan.unlimited: 15000,
};

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
          builder: (context, walletSnap) {
            final currentPlan = walletSnap.data?.plan ?? TokenPlan.free;

            return StreamBuilder<Map<String, dynamic>?>(
              stream: TokenService().transferableWalletStream,
              builder: (context, p2pSnap) {
                final p2pBalance = p2pSnap.data?['balanceMinor'] as int? ?? 0;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionHeader(
                      icon: Icons.workspace_premium_rounded,
                      title: l10n.tokenShopChoosePlanTitle,
                      subtitle: l10n.tokenShopChoosePlanSubtitle,
                    ),
                    const SizedBox(height: 8),
                    // Sold curent P2P (pentru context)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.violetAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.violetAccent),
                            const SizedBox(width: 6),
                            Text(
                              'Sold Transferabil: $p2pBalance Tokeni',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.violetAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...catalog.expand((doc) {
                      final plan = doc.tokenPlan;
                      if (plan == null) return const Iterable<Widget>.empty();
                      return [
                        _PlanCard(
                          plan: plan,
                          monthlyAllowance: doc.monthlyAllowance,
                          isCurrent: plan == currentPlan,
                          onSelect: () => _selectPlan(context, plan, currentPlan, p2pBalance),
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
      },
    );
  }

  void _selectPlan(BuildContext context, TokenPlan plan, TokenPlan current, int p2pBalance) {
    final l10n = AppLocalizations.of(context)!;
    if (plan == current) {
      AppFeedback.info(context, l10n.tokenShopAlreadyOnPlan);
      return;
    }
    if (plan == TokenPlan.free) {
      AppFeedback.warning(context, l10n.tokenShopDowngradeContactSupport);
      return;
    }

    final planName = _tokenPlanDisplayName(plan, l10n);
    final ronPrice = _tokenPlanPriceLabel(plan, l10n);
    final tokenPrice = kPlanTokenPrices[plan] ?? 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tokenShopChoosePaymentMethodFor(planName),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 20),
              // Opțiunea 1: Card/Bancar
              ListTile(
                leading: const Icon(Icons.credit_card_rounded, color: AppColors.violetAccent),
                title: Text(l10n.tokenShopPayByCard, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l10n.tokenShopPriceWithAutoRenewal(ronPrice)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPaymentDialog(context, planName, ronPrice, () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;
                    await TokenService().upgradePlan(uid, plan);
                  });
                },
              ),
              const SizedBox(height: 12),
              // Opțiunea 2: Tokeni (P2P)
              ListTile(
                enabled: p2pBalance >= tokenPrice,
                leading: Icon(Icons.generating_tokens_outlined, 
                    color: p2pBalance >= tokenPrice ? Colors.teal : Colors.grey),
                title: Text(l10n.tokenShopPayWithTransferableTokens, 
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l10n.tokenShopPriceInTokensNoRenewal(tokenPrice)),
                trailing: p2pBalance < tokenPrice 
                    ? Text(l10n.tokenShopInsufficientShort, style: const TextStyle(color: Colors.red, fontSize: 10))
                    : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: p2pBalance >= tokenPrice ? Colors.teal.shade100 : Colors.grey.shade200)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await TokenService().purchasePlanWithTokens(plan.name);
                    if (context.mounted) {
                      AppFeedback.success(context, l10n.tokenShopPlanActivated(planName));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppFeedback.error(context, l10n.tokenShopErrorWithMessage(e.toString()));
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
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
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planName = _tokenPlanDisplayName(widget.plan, l10n);
    final price = _tokenPlanPriceLabel(widget.plan, l10n);
    final allowanceStr = widget.monthlyAllowance >= 999999998 ? '∞' : '${widget.monthlyAllowance}';
    final economy = TokenEconomySummary.fromMonthlyAllowance(widget.monthlyAllowance);
    final isPopular = widget.plan == TokenPlan.basic;
    
    // Aesthetic Colors
    const darkMatter = Color(0xFF131620);
    const neonCyan = Color(0xFF00E5FF);
    const neonAmber = Color(0xFFFFB300);
    const neonViolet = Color(0xFF7C3AED);
    
    final accentColor = widget.isCurrent ? neonCyan : (isPopular ? neonAmber : neonViolet);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onSelect();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: darkMatter,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isCurrent 
                  ? accentColor.withValues(alpha: 0.6) 
                  : Colors.white.withValues(alpha: 0.05),
              width: widget.isCurrent ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (widget.isCurrent || isPopular)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle background glow
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dynamic Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(_planIcon(widget.plan), color: accentColor, size: 26),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                planName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (isPopular && !widget.isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: neonAmber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: neonAmber.withValues(alpha: 0.4)),
                                  ),
                                  child: const Text(
                                    'POPULAR',
                                    style: TextStyle(color: neonAmber, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$allowanceStr Tokeni',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (economy.isUnlimited)
                            Text(
                              l10n.tokenShopUnlimitedAccessNetworkIntelligence,
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                            )
                          else
                            Text(
                              '~${economy.aiQueries} AI Queries | ~${economy.routeCalcs} Rute',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                            ),
                        ],
                      ),
                    ),
                    // Price & Action
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.plan != TokenPlan.free)
                          Text(
                            'sau ${kPlanTokenPrices[widget.plan]} TKN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: neonCyan.withValues(alpha: 0.7),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (widget.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: neonCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: neonCyan.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'ACTIV',
                              style: TextStyle(fontSize: 10, color: neonCyan, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          )
                        else if (widget.plan != TokenPlan.free)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))
                              ],
                            ),
                            child: const Text(
                              'SELECT',
                              style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final personalPackages = _topupPackages(l10n);
    final transferablePackages = _transferablePackages(l10n);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Secțiunea 1: Uz Personal
        _SectionHeader(
          icon: Icons.person_outline_rounded,
          title: l10n.tokenShopBuyExtraTitle,
          subtitle: l10n.tokenShopPersonalTokensSubtitle,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: personalPackages
              .map((p) => _TopupCard(
                    package: p,
                    onBuy: () => _buyPackage(context, p),
                  ))
              .toList(),
        ),

        const SizedBox(height: 32),

        // Secțiunea 2: Transferabili (Nou!)
        _SectionHeader(
          icon: Icons.card_giftcard_rounded,
          title: l10n.tokenShopTransferablePackagesTitle,
          subtitle: l10n.tokenShopTransferablePackagesSubtitle,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: transferablePackages
              .map((p) => _TopupCard(
                    package: p,
                    isTransferable: true,
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
    final title = pkg.isTransferable 
        ? l10n.tokenShopTransferablePackageTitle(pkg.tokens)
        : '${pkg.tokens} ${l10n.tokenShopTokensWord} (${pkg.label})';

    _showPaymentDialog(
      context,
      title,
      pkg.price,
      () async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        try {
          await TokenService().addTokens(
            uid,
            pkg.tokens,
            TokenTransactionType.purchase,
            isTransferable: pkg.isTransferable,
            description: pkg.isTransferable 
                ? l10n.tokenShopTxPurchaseTransferablePackage(pkg.label)
                : l10n.tokenShopTxPurchasePackage(pkg.label, pkg.tokens),
          );
          if (context.mounted) {
            AppFeedback.success(
              context,
              l10n.tokenShopTokensAdded(pkg.tokens) +
                  (pkg.isTransferable ? l10n.tokenShopTransferableWalletSuffix : ''),
            );
          }
        } on FirebaseFunctionsException catch (e) {
          if (!context.mounted) return;
          AppFeedback.error(
            context,
            e.code == 'failed-precondition'
                ? l10n.tokenShopTopupRequiresBackend
                : l10n.tokenShopErrorWithMessage(e.message ?? e.code),
          );
        } catch (e) {
          if (!context.mounted) return;
          AppFeedback.error(context, l10n.tokenShopErrorWithMessage(e.toString()));
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
  final bool isTransferable;
  const _TopupPackage({
    required this.tokens,
    required this.price,
    required this.label,
    this.popular = false,
    this.isTransferable = false,
  });
}

class _TopupCard extends StatelessWidget {
  final _TopupPackage package;
  final VoidCallback onBuy;
  final bool isTransferable;

  const _TopupCard({
    required this.package,
    required this.onBuy,
    this.isTransferable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = isTransferable ? theme.colorScheme.tertiary : AppColors.violetAccent;
    final surface = theme.colorScheme.surface;
    
    return InkWell(
      onTap: onBuy,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: package.popular ? accent : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: package.popular
                ? accent
                : theme.dividerColor.withValues(alpha: 0.35),
            width: isTransferable ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (package.popular || isTransferable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTransferable ? 'GIFT' : l10n.tokenShopPopularBadge,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${package.tokens}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit',
                    color: package.popular
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (isTransferable)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.share_rounded, size: 14, color: Colors.white70),
                  ),
              ],
            ),
            Text(
              l10n.tokenShopTokensWord,
              style: TextStyle(
                fontSize: 11,
                color: package.popular
                    ? Colors.white70
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const Spacer(),
            Text(
              package.price,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: package.popular ? Colors.white : accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Istoric tranzacții — cu categorii și buton ștergere
// ─────────────────────────────────────────────────────────────────────────────

enum _TxCategory { all, purchases, ai, routes, posts, bonuses, admin }

extension _TxCategoryExt on _TxCategory {
  String get displayLabel => switch (this) {
    _TxCategory.all       => 'Toate',
    _TxCategory.purchases => 'Cumpărări',
    _TxCategory.ai        => 'AI',
    _TxCategory.routes    => 'Rute',
    _TxCategory.posts     => 'Postări',
    _TxCategory.bonuses   => 'Bonusuri',
    _TxCategory.admin     => 'Admin',
  };

  IconData get icon => switch (this) {
    _TxCategory.all       => Icons.list_rounded,
    _TxCategory.purchases => Icons.shopping_cart_rounded,
    _TxCategory.ai        => Icons.auto_awesome_rounded,
    _TxCategory.routes    => Icons.map_rounded,
    _TxCategory.posts     => Icons.campaign_rounded,
    _TxCategory.bonuses   => Icons.card_giftcard_rounded,
    _TxCategory.admin     => Icons.admin_panel_settings_rounded,
  };

  Color get color => switch (this) {
    _TxCategory.all       => Colors.blueGrey,
    _TxCategory.purchases => Colors.green,
    _TxCategory.ai        => Colors.purple,
    _TxCategory.routes    => Colors.blue,
    _TxCategory.posts     => Colors.orange,
    _TxCategory.bonuses   => Colors.teal,
    _TxCategory.admin     => Colors.redAccent,
  };

  bool matches(TokenTransactionType type) => switch (this) {
    _TxCategory.all       => true,
    _TxCategory.purchases => type == TokenTransactionType.purchase,
    _TxCategory.ai        => type == TokenTransactionType.aiQuery,
    _TxCategory.routes    => type == TokenTransactionType.routeCalc ||
                             type == TokenTransactionType.geocoding,
    _TxCategory.posts     => type == TokenTransactionType.broadcastPost ||
                             type == TokenTransactionType.businessOffer,
    _TxCategory.bonuses   => type == TokenTransactionType.bonus ||
                             type == TokenTransactionType.monthlyReset,
    _TxCategory.admin     => type == TokenTransactionType.adminAdjust,
  };
}

_TxCategory _categoryForType(TokenTransactionType type) {
  for (final cat in _TxCategory.values) {
    if (cat != _TxCategory.all && cat.matches(type)) return cat;
  }
  return _TxCategory.admin;
}

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<TokenTransaction>? _transactions;
  _TxCategory _filter = _TxCategory.all;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txs = await TokenService().getTransactionHistory(limit: 100);
    if (mounted) setState(() => _transactions = txs);
  }

  List<TokenTransaction> get _filtered {
    if (_transactions == null) return [];
    if (_filter == _TxCategory.all) return _transactions!;
    return _transactions!.where((t) => _filter.matches(t.type)).toList();
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge istoricul'),
        content: const Text(
          'Toate tranzacțiile vor fi șterse permanent.\nSoldul și planul curent rămân neafectate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await TokenService().clearTransactionHistory();
      if (mounted) {
        setState(() {
          _transactions = [];
          _deleting = false;
          _filter = _TxCategory.all;
        });
        AppFeedback.success(context, 'Istoricul a fost șters.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        AppFeedback.error(context, 'Eroare: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    if (_transactions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ── Filtru categorii ────────────────────────────────────────────
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: _TxCategory.values.map((cat) {
              final active = _filter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: active,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 13,
                          color: active ? Colors.white : cat.color),
                      const SizedBox(width: 4),
                      Text(cat.displayLabel),
                    ],
                  ),
                  onSelected: (_) => setState(() => _filter = cat),
                  selectedColor: cat.color,
                  checkmarkColor: Colors.transparent,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Header contor + buton ștergere ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
          child: Row(
            children: [
              Text(
                '${_filtered.length} tranzacții',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const Spacer(),
              if (_transactions!.isNotEmpty)
                _deleting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _confirmClear,
                        icon: const Icon(Icons.delete_sweep_rounded,
                            size: 16, color: Colors.red),
                        label: const Text(
                          'Șterge tot',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Lista ───────────────────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _transactions!.isEmpty
                          ? 'Nu există tranzacții înregistrate.'
                          : 'Nicio tranzacție în categoria selectată.',
                      style: TextStyle(color: muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _filter == _TxCategory.all
                  ? _buildGroupedList()
                  : _buildFlatList(_filtered),
        ),
      ],
    );
  }

  Widget _buildGroupedList() {
    final grouped = <_TxCategory, List<TokenTransaction>>{};
    for (final tx in _transactions!) {
      grouped.putIfAbsent(_categoryForType(tx.type), () => []).add(tx);
    }
    final orderedCats = _TxCategory.values
        .where((c) => c != _TxCategory.all && grouped.containsKey(c))
        .toList();

    final items = <Widget>[];
    for (final cat in orderedCats) {
      final txList = grouped[cat]!;
      items.add(_CategoryHeader(category: cat, count: txList.length));
      items.addAll(txList.map((tx) => _TxTile(tx: tx)));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: items,
    );
  }

  Widget _buildFlatList(List<TokenTransaction> items) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _TxTile(tx: items[i]),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final _TxCategory category;
  final int count;
  const _CategoryHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, size: 14, color: category.color),
          ),
          const SizedBox(width: 10),
          Text(
            category.displayLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: category.color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: category.color,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Divider(
                  height: 1,
                  color: category.color.withValues(alpha: 0.2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TokenTransaction tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.amount > 0;
    final cat = _categoryForType(tx.type);
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isPositive
            ? Colors.green.shade50
            : cat.color.withValues(alpha: 0.10),
        child: Icon(
          isPositive ? Icons.add_rounded : cat.icon,
          color: isPositive ? Colors.green.shade600 : cat.color,
          size: 16,
        ),
      ),
      title: Text(
        tx.description,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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

List<_TopupPackage> _transferablePackages(AppLocalizations l10n) => [
      const _TopupPackage(
        tokens: 100,
        price: '0,99 RON',
        label: 'Micro Gift',
        isTransferable: true,
      ),
      const _TopupPackage(
        tokens: 1000,
        price: '7,99 RON',
        label: 'Standard Gift',
        isTransferable: true,
        popular: true,
      ),
      const _TopupPackage(
        tokens: 5000,
        price: '34,99 RON',
        label: 'Premium Gift',
        isTransferable: true,
      ),
    ];
