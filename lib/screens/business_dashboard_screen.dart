import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/models/business_offer_model.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/screens/business_mystery_redeem_screen.dart';
import 'package:nabour_app/screens/business_offer_create_screen.dart';
import 'package:nabour_app/screens/business_profile_edit_screen.dart';
import 'package:nabour_app/screens/magic_event_list_screen.dart';
import 'package:nabour_app/services/business_service.dart';
import 'package:nabour_app/services/token_service.dart';

class BusinessDashboardScreen extends StatelessWidget {
  final String profileId;

  const BusinessDashboardScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Panoul meu de Business'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<BusinessProfile?>(
        stream: BusinessService().myProfileStream,
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Verificare expirare abonament — fire-and-forget
          if (!profile.isSuspended &&
              profile.subscriptionExpiresAt != null &&
              DateTime.now().isAfter(profile.subscriptionExpiresAt!)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              BusinessService().suspendBusiness(profile.id);
            });
          }

          return Column(
            children: [
              _GlassHeader(
                profile: profile,
                onOpenSettings: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          BusinessProfileEditScreen(profile: profile),
                    ),
                  );
                },
                onValidateMysteryCode: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          BusinessMysteryRedeemScreen(profile: profile),
                    ),
                  );
                },
                onMagicEvents: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MagicEventListScreen(profile: profile),
                    ),
                  );
                },
              ),
              if (profile.isSuspended)
                _SuspensionBanner(profile: profile),
              Expanded(
                child: StreamBuilder<List<BusinessOffer>>(
                  stream: BusinessService().myOffersStream(profile.id),
                  builder: (context, offersSnap) {
                    final offers = offersSnap.data ?? [];

                    if (offersSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (offers.isEmpty) {
                      return _EmptyState(profile: profile);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: offers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) => _OfferCard(
                        profile: profile,
                        offer: offers[i],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<BusinessProfile?>(
        stream: BusinessService().myProfileStream,
        builder: (context, snap) {
          final profile = snap.data;
          if (profile == null) return const SizedBox.shrink();
          if (profile.isSuspended) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BusinessOfferCreateScreen(profile: profile),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Anunț nou'),
          );
        },
      ),
    );
  }
}

// ── Glassmorphism Header ──────────────────────────────────────────────────────

class _GlassHeader extends StatelessWidget {
  final BusinessProfile profile;
  final VoidCallback onOpenSettings;
  final VoidCallback onValidateMysteryCode;
  final VoidCallback onMagicEvents;

  const _GlassHeader({
    required this.profile,
    required this.onOpenSettings,
    required this.onValidateMysteryCode,
    required this.onMagicEvents,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.primary.withAlpha(180),
            colors.tertiary.withAlpha(120),
          ],
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha(25),
                  Colors.white.withAlpha(10),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withAlpha(40),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar categorie
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          profile.category.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.businessName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.category.displayNameForLanguage(lang),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.address,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onValidateMysteryCode,
                      tooltip: 'Validează cod Mystery Box',
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: onMagicEvents,
                      tooltip: 'Evenimente pe hartă (Magic Check-in)',
                      icon: const Icon(Icons.auto_awesome_rounded),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: onOpenSettings,
                      tooltip: 'Card afacere & setări',
                      icon: const Icon(Icons.settings_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row: tokeni + cost
                StreamBuilder<TokenWallet?>(
                  stream: TokenService().walletStream,
                  builder: (context, snap) {
                    final balance = snap.data?.balance ?? 0;
                    final affordableOffers =
                        (balance / TokenCost.businessOffer).floor();

                    return Row(
                      children: [
                        _StatChip(
                          icon: Icons.toll_rounded,
                          value: '$balance',
                          label: 'tokeni disponibili',
                        ),
                        const SizedBox(width: 10),
                        _StatChip(
                          icon: Icons.campaign_rounded,
                          value: '$affordableOffers',
                          label: 'anunțuri posibile',
                        ),
                        const SizedBox(width: 10),
                        const _StatChip(
                          icon: Icons.payments_outlined,
                          value: '${TokenCost.businessOffer}',
                          label: 'tokeni/anunț',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Suspension Banner ─────────────────────────────────────────────────────────

class _SuspensionBanner extends StatelessWidget {
  final BusinessProfile profile;
  const _SuspensionBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final exp = profile.subscriptionExpiresAt;
    final expStr = exp != null
        ? DateFormat('dd MMM yyyy', 'ro_RO').format(exp)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.red.shade700,
      child: Row(
        children: [
          const Icon(Icons.block_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cont suspendat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  expStr != null
                      ? 'Abonamentul a expirat pe $expStr. Reînnoiți pentru a reactiva anunțurile.'
                      : 'Abonamentul a expirat. Reînnoiți pentru a reactiva anunțurile.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final BusinessProfile profile;
  const _EmptyState({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined,
              size: 64, color: colors.onSurface.withAlpha(80)),
          const SizedBox(height: 16),
          Text(
            'Niciun anunț activ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface.withAlpha(120),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apasă + pentru a publica primul anunț.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withAlpha(100),
                ),
          ),
        ],
      ),
    );
  }
}

// ── Offer Card ────────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final BusinessProfile profile;
  final BusinessOffer offer;

  const _OfferCard({required this.profile, required this.offer});

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge anunțul?'),
        content: Text('„${offer.title}" va fi dezactivat imediat.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anulează')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Șterge')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await BusinessService().deleteOffer(offer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Anunț șters.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Eroare: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm', 'ro_RO').format(offer.createdAt);
    final isFlash = offer.isFlash;

    return Card(
      elevation: isFlash ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFlash
            ? const BorderSide(color: Color(0xFFFF6B35), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isFlash) ...[
                  const Icon(Icons.bolt_rounded,
                      size: 16, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    offer.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isFlash
                              ? const Color(0xFFFF6B35)
                              : null,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: colors.primary,
                  tooltip: 'Editează anunțul',
                  onPressed: profile.isSuspended
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Cont suspendat — nu poți modifica anunțuri.'),
                            ),
                          );
                        }
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BusinessOfferCreateScreen(
                                profile: profile,
                                existingOffer: offer,
                              ),
                            ),
                          );
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: colors.error,
                  tooltip: 'Șterge anunțul',
                  onPressed: () => _delete(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              offer.description,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 12, color: colors.onSurface.withAlpha(120)),
                const SizedBox(width: 4),
                Text(
                  '${offer.viewsCount} vizualizări',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withAlpha(120),
                      ),
                ),
                const Spacer(),
                Icon(Icons.access_time_rounded,
                    size: 12, color: colors.onSurface.withAlpha(120)),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withAlpha(120),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
