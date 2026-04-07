import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/theme/app_colors.dart';

/// Widget compact afișat în drawer și profil — sold + bară progres.
///
/// Variante:
///   [TokenWalletWidget.drawer]  — versiune mică pentru side drawer
///   [TokenWalletWidget.profile] — versiune mare pentru ecranul de cont
class TokenWalletWidget extends StatelessWidget {
  final _Style _style;

  const TokenWalletWidget.drawer({super.key}) : _style = _Style.drawer;
  const TokenWalletWidget.profile({super.key}) : _style = _Style.profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TokenWallet?>(
      stream: TokenService().walletStream,
      builder: (context, snap) {
        final wallet = snap.data;
        if (wallet == null) return const SizedBox.shrink();
        return _style == _Style.drawer
            ? _DrawerTile(wallet: wallet)
            : _ProfileCard(wallet: wallet);
      },
    );
  }
}

enum _Style { drawer, profile }

// ── Drawer tile — compact ─────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final TokenWallet wallet;
  const _DrawerTile({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const violet = AppColors.violetAccent;
    final ratio = wallet.usageRatio;
    final color = _barColor(ratio);
    final allowance = wallet.plan.monthlyAllowance;
    final spent = (allowance - wallet.balance).clamp(0, allowance);
    final allowanceStr =
        allowance >= 999999999 ? '∞' : allowance.toString();
    final when = _resetLabel(wallet.resetAt, l10n);

    return InkWell(
      onTap: () => _openShop(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: violet.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: violet.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.toll_rounded, size: 16, color: violet),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.tokenWalletBalanceShort(
                      wallet.balance.toStringAsFixed(0),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: violet.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _tokenPlanDisplayName(wallet.plan, l10n),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: violet,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tokenWalletDrawerSubline(
                spent.toString(),
                allowanceStr,
                when,
              ),
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile card — extins ─────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final TokenWallet wallet;
  const _ProfileCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const violet = AppColors.violetAccent;
    final ratio = wallet.usageRatio;
    final color = _barColor(ratio);
    final allowance = wallet.plan.monthlyAllowance;
    final spent = (allowance - wallet.balance).clamp(0, allowance);
    final pct = (ratio * 100).toStringAsFixed(0);
    final allowanceStr =
        allowance >= 999999999 ? '∞' : allowance.toString();
    final when = _resetLabel(wallet.resetAt, l10n);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [violet, violet.withValues(alpha: 0.85)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.toll_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tokenWalletAvailableLong('${wallet.balance}'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.tokenWalletPlanLine(
                          _tokenPlanDisplayName(wallet.plan, l10n),
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bara de progres ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tokenWalletUsedThisMonth,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        l10n.tokenWalletPercentUsage(
                          pct,
                          spent.toString(),
                          allowanceStr,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.tokenWalletAutoReset(when),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Statistici rapide ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _StatChip(
                  label: l10n.tokenWalletStatTotalSpent,
                  value: '${wallet.totalSpent}',
                  icon: Icons.trending_down_rounded,
                  color: Colors.red.shade400,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: l10n.tokenWalletStatTotalEarned,
                  value: '${wallet.totalEarned}',
                  icon: Icons.trending_up_rounded,
                  color: Colors.green.shade500,
                ),
              ],
            ),
          ),

          // ── Buton cumpărare ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openShop(context),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(
                  l10n.tokenWalletOpenShopCta,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── StatChip ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _barColor(double ratio) {
  if (ratio < 0.6) return Colors.green.shade500;
  if (ratio < 0.85) return Colors.orange.shade400;
  return Colors.red.shade500;
}

String _resetLabel(DateTime resetAt, AppLocalizations l10n) {
  final diff = resetAt.difference(DateTime.now());
  if (diff.inDays > 1) {
    return l10n.tokenWalletResetInDays(diff.inDays);
  }
  if (diff.inHours > 0) {
    return l10n.tokenWalletResetInHours(diff.inHours);
  }
  return l10n.tokenWalletResetTomorrow;
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

void _openShop(BuildContext context) {
  // Navigare spre TokenShopScreen (implementat separat)
  Navigator.of(context).pushNamed('/token-shop');
}
