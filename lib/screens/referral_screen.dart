import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nabour_app/models/referral_model.dart';
import 'package:nabour_app/services/referral_service.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/theme/app_text_styles.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _service = ReferralService();
  String? _referralCode;
  bool _loadingCode = true;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final code = await _service.getReferralCode(uid) ??
        (await _service.createReferralCode(uid));
    setState(() {
      _referralCode = code;
      _loadingCode = false;
    });
  }

  void _copyCode() {
    if (_referralCode == null) return;
    Clipboard.setData(ClipboardData(text: _referralCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cod copiat!')),
    );
  }

  void _shareCode() {
    if (_referralCode == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: 'Folosește codul meu de referral $_referralCode pe Nabour! Descarcă aplicația: https://nabour.app',
        subject: 'Cod referral Nabour',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Referral', style: AppTextStyles.heading3),
        backgroundColor: AppColors.surface,
      ),
      body: uid == null
          ? const Center(child: Text('Autentifică-te mai întâi.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReferralCard(),
                  const SizedBox(height: 20),
                  _buildStatsCard(uid),
                  const SizedBox(height: 20),
                  _buildHowItWorks(),
                  const SizedBox(height: 20),
                  _buildReferralsList(uid),
                ],
              ),
            ),
    );
  }

  Widget _buildReferralCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.share, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Codul tău de referral', style: AppTextStyles.heading4),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingCode)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _referralCode ?? '',
                      style: AppTextStyles.heading3
                          .copyWith(letterSpacing: 4, color: AppColors.primary),
                    ),
                    IconButton(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy),
                      color: AppColors.primary,
                      tooltip: 'Copiază',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareCode,
                icon: const Icon(Icons.share),
                label: const Text('Distribuie codul'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String uid) {
    return FutureBuilder<ReferralStats?>(
      future: _service.getReferralStats(uid),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Statistici', style: AppTextStyles.heading4),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(
                        '${stats?.totalReferrals ?? 0}', 'Total'),
                    _statItem(
                        '${stats?.completedReferrals ?? 0}', 'Completați'),
                    _statItem(
                        '${stats?.totalRewardsEarned.toInt() ?? 0} RON', 'Câștigat'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style:
                AppTextStyles.heading3.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      const _StepItem(Icons.share_outlined, 'Distribuie codul tău prietenilor'),
      const _StepItem(Icons.person_add_outlined,
          'Prietenii se înregistrează cu codul tău'),
      const _StepItem(Icons.directions_car_outlined,
          'Fac prima cursă verificată'),
      const _StepItem(Icons.card_giftcard_outlined,
          'Voi amândoi primiți un bonus de 10 RON'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Cum funcționează?', style: AppTextStyles.heading4),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(e.value.text,
                            style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralsList(String uid) {
    return FutureBuilder<List<Referral>>(
      future: _service.getReferrals(uid),
      builder: (context, snapshot) {
        final referrals = snapshot.data ?? [];
        if (referrals.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Referralurile tale', style: AppTextStyles.heading4),
            const SizedBox(height: 12),
            ...referrals.map((r) => _buildReferralItem(r)),
          ],
        );
      },
    );
  }

  Widget _buildReferralItem(Referral referral) {
    final statusColors = {
      ReferralStatus.pending: Colors.orange,
      ReferralStatus.completed: AppColors.secondary,
      ReferralStatus.rewarded: AppColors.primary,
      ReferralStatus.expired: AppColors.textHint,
    };
    final statusLabel = {
      ReferralStatus.pending: 'În așteptare',
      ReferralStatus.completed: 'Completat',
      ReferralStatus.rewarded: 'Recompensat',
      ReferralStatus.expired: 'Expirat',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(referral.referredEmail ?? referral.referredPhone ?? 'Utilizator nou',
            style: AppTextStyles.bodyLarge),
        subtitle: Text(
          '${referral.createdAt.toDate().day}.${referral.createdAt.toDate().month}.${referral.createdAt.toDate().year}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:
                (statusColors[referral.status] ?? Colors.grey).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusLabel[referral.status] ?? referral.status.name,
            style: AppTextStyles.bodySmall.copyWith(
              color: statusColors[referral.status] ?? Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepItem {
  final IconData icon;
  final String text;
  const _StepItem(this.icon, this.text);
}
