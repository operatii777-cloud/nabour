import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/gift_ride_model.dart';
import 'package:nabour_app/services/gift_ride_service.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/theme/app_text_styles.dart';

class GiftRideScreen extends StatefulWidget {
  const GiftRideScreen({super.key});

  @override
  State<GiftRideScreen> createState() => _GiftRideScreenState();
}

class _GiftRideScreenState extends State<GiftRideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GiftRideService _service = GiftRideService();

  // Send form fields
  final _formKey = GlobalKey<FormState>();
  final _recipientNameCtrl = TextEditingController();
  final _recipientEmailCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  double _selectedAmount = 50.0;
  bool _isSending = false;

  static const List<double> _amountOptions = [20, 30, 50, 75, 100, 150];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipientNameCtrl.dispose();
    _recipientEmailCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendGift() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnack('Trebuie să fii autentificat.', isError: true);
      return;
    }
    setState(() => _isSending = true);
    try {
      final gift = await _service.sendGiftRide(
        recipientName: _recipientNameCtrl.text.trim(),
        recipientEmail: _recipientEmailCtrl.text.trim().isEmpty
            ? null
            : _recipientEmailCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim().isEmpty
            ? null
            : _recipientPhoneCtrl.text.trim(),
        amount: _selectedAmount,
        message: _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
      );
      _showSnack('Cadoul a fost trimis! Cod: ${gift?.code ?? ''}');
      _formKey.currentState!.reset();
      _tabController.animateTo(1);
    } catch (e) {
      _showSnack('Eroare la trimitere: $e', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cadou Cursă', style: AppTextStyles.heading3),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Trimite cadou'),
            Tab(text: 'Cadourile mele'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSendTab(), _buildMyGiftsTab()],
      ),
    );
  }

  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Destinatar', style: AppTextStyles.heading4),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recipientNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nume*',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Introdu un nume' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recipientEmailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email (opțional)',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recipientPhoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefon (opțional)',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            const Text('Suma (RON)', style: AppTextStyles.heading4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _amountOptions.map((amount) {
                final selected = _selectedAmount == amount;
                return ChoiceChip(
                  label: Text('${amount.toInt()} RON'),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _selectedAmount = amount),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Mesaj personalizat', style: AppTextStyles.heading4),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageCtrl,
              decoration: const InputDecoration(
                labelText: 'Mesaj (opțional)',
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendGift,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.card_giftcard),
                label: Text(
                    _isSending ? 'Se trimite...' : 'Trimite ${_selectedAmount.toInt()} RON'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGiftsTab() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Autentifică-te pentru a vedea cadourile.'));
    }
    return FutureBuilder<List<GiftRide>>(
      future: _service.getUserSentGifts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final gifts = snapshot.data ?? [];
        if (gifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard_outlined,
                    size: 72, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('Nu ai trimis niciun cadou încă.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: gifts.length,
          itemBuilder: (_, i) => _buildGiftCard(gifts[i]),
        );
      },
    );
  }

  Widget _buildGiftCard(GiftRide gift) {
    final statusColors = {
      GiftRideStatus.pending: Colors.orange,
      GiftRideStatus.claimed: AppColors.secondary,
      GiftRideStatus.expired: AppColors.textHint,
      GiftRideStatus.cancelled: AppColors.error,
    };
    final statusLabels = {
      GiftRideStatus.pending: 'În așteptare',
      GiftRideStatus.claimed: 'Revendicat',
      GiftRideStatus.expired: 'Expirat',
      GiftRideStatus.cancelled: 'Anulat',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('${gift.amount.toInt()}',
                  style: AppTextStyles.heading4
                      .copyWith(color: AppColors.primary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gift.recipientName, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 4),
                  Text('Cod: ${gift.code}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (statusColors[gift.status] ?? Colors.grey).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabels[gift.status] ?? gift.status.name,
                style: AppTextStyles.bodySmall.copyWith(
                  color: statusColors[gift.status] ?? Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
