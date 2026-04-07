import 'package:flutter/material.dart';
import 'package:nabour_app/models/business_offer_model.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/business_service.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/content_filter.dart';

class BusinessOfferCreateScreen extends StatefulWidget {
  final BusinessProfile profile;

  /// Dacă e setat, ecranul devine editare (fără cost tokeni).
  final BusinessOffer? existingOffer;

  const BusinessOfferCreateScreen({
    super.key,
    required this.profile,
    this.existingOffer,
  });

  bool get isEditMode => existingOffer != null;

  @override
  State<BusinessOfferCreateScreen> createState() =>
      _BusinessOfferCreateScreenState();
}

class _BusinessOfferCreateScreenState
    extends State<BusinessOfferCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _mysteryBoxSlotsCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isFlash = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.existingOffer;
    if (edit != null) {
      _titleCtrl.text = edit.title;
      _descCtrl.text = edit.description;
      if (edit.link != null && edit.link!.isNotEmpty) {
        _linkCtrl.text = edit.link!;
      }
      _phoneCtrl.text = edit.phone ?? widget.profile.phone;
      _whatsappCtrl.text =
          edit.whatsapp ?? widget.profile.whatsapp ?? '';
      _isFlash = edit.isFlash;
      final cap = edit.mysteryBoxTotal;
      if (cap != null && cap > 0) {
        _mysteryBoxSlotsCtrl.text = '$cap';
      }
    } else {
      _phoneCtrl.text = widget.profile.phone;
      if (widget.profile.whatsapp != null) {
        _whatsappCtrl.text = widget.profile.whatsapp!;
      }
      _checkAndShowPaymentIfNeeded();
    }
    _mysteryBoxSlotsCtrl.addListener(_onMysterySlotsChanged);
  }

  void _onMysterySlotsChanged() {
    if (mounted) setState(() {});
  }

  /// Număr de cutii pentru previzualizare cost (doar dacă e valid 1…max; altfel 0).
  int _previewMysterySlots() {
    final t = _mysteryBoxSlotsCtrl.text.trim();
    if (t.isEmpty) return 0;
    final n = int.tryParse(t);
    if (n == null || n < 1 || n > _kMysteryBoxMaxSlots) return 0;
    return n;
  }

  int _createOfferTotalTokens() =>
      TokenCost.businessOfferWithMysterySlots(_previewMysterySlots());

  /// Cutii noi facturate la salvare în modul edit (față de plafonul existent).
  int _editExtraMysteryTokenCost() {
    final edit = widget.existingOffer;
    if (edit == null) return 0;
    final slots = _parseMysteryBoxSlotsForEdit();
    if (slots < 0) return 0;
    final oldCap = edit.mysteryBoxTotal ?? 0;
    if (slots <= oldCap) return 0;
    return TokenCost.mysteryBoxSlotsTokenCost(slots - oldCap);
  }

  Future<void> _checkAndShowPaymentIfNeeded() async {
    final wallet = await TokenService().getWallet();
    if (!mounted) return;
    if ((wallet?.balance ?? 0) < _createOfferTotalTokens()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPaymentSheet(tokensRequired: _createOfferTotalTokens());
        }
      });
    }
  }

  void _showPaymentSheet({
    int? tokensRequired,
    String? costHint,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PurchaseOfferSheet(
        onGoToShop: () {
          Navigator.pop(context); // închide sheet-ul
          Navigator.of(context).pushNamed('/token-shop');
        },
        tokensRequired: tokensRequired,
        costHint: costHint,
      ),
    );
  }

  @override
  void dispose() {
    _mysteryBoxSlotsCtrl.removeListener(_onMysterySlotsChanged);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _mysteryBoxSlotsCtrl.dispose();
    super.dispose();
  }

  static const int _kMysteryBoxMaxSlots = 100000;

  /// Pentru creare: `null` = nelimitat. Pentru editare: trimite mereu o valoare (0 = scoate plafonul).
  int? _parseMysteryBoxSlotsForCreate() {
    final t = _mysteryBoxSlotsCtrl.text.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 1) return -1;
    if (n > _kMysteryBoxMaxSlots) return -2;
    return n;
  }

  /// La salvare în modul edit: 0 = nelimitat (șterge câmpul în Firestore).
  int _parseMysteryBoxSlotsForEdit() {
    final t = _mysteryBoxSlotsCtrl.text.trim();
    if (t.isEmpty) return 0;
    final n = int.tryParse(t);
    if (n == null || n < 1) return -1;
    if (n > _kMysteryBoxMaxSlots) return -2;
    return n;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ── Filtru conținut ────────────────────────────────────────────────
    final titleCheck = ContentFilter.check(_titleCtrl.text);
    final descCheck = ContentFilter.check(_descCtrl.text);
    if (!titleCheck.isClean || !descCheck.isClean) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (!titleCheck.isClean ? titleCheck.message : descCheck.message) ??
                'Conținutul anunțului conține limbaj inadecvat.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final edit = widget.existingOffer;
      if (edit != null) {
        final slots = _parseMysteryBoxSlotsForEdit();
        if (slots == -1 || slots == -2) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                slots == -2
                    ? 'Numărul de cutii Mystery Box nu poate depăși $_kMysteryBoxMaxSlots.'
                    : 'Introdu un număr valid de cutii (≥ 1) sau lasă gol pentru nelimitat.',
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }
        await BusinessService().updateOffer(
          offerId: edit.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          whatsapp: _whatsappCtrl.text.trim().isEmpty
              ? null
              : _whatsappCtrl.text.trim(),
          isFlash: _isFlash,
          profile: widget.profile,
          mysteryBoxTotal: slots,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anunț actualizat.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      final parsedSlots = _parseMysteryBoxSlotsForCreate();
      if (parsedSlots != null && parsedSlots < 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              parsedSlots == -2
                  ? 'Numărul de cutii Mystery Box nu poate depăși $_kMysteryBoxMaxSlots.'
                  : 'Introdu un număr valid de cutii (≥ 1) sau lasă gol pentru nelimitat.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      final offer = BusinessOffer(
        id: '',
        businessId: widget.profile.id,
        businessName: widget.profile.businessName,
        businessCategory: widget.profile.category,
        businessLatitude: widget.profile.latitude,
        businessLongitude: widget.profile.longitude,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim().isEmpty
            ? null
            : _whatsappCtrl.text.trim(),
        isFlash: _isFlash,
        createdAt: DateTime.now(),
        mysteryBoxTotal: parsedSlots,
        mysteryBoxClaimed: 0,
      );

      await BusinessService().createOffer(offer);

      if (!mounted) return;
      final spent = TokenCost.businessOfferWithMysterySlots(parsedSlots ?? 0);
      final slotN = parsedSlots ?? 0;
      final msg = slotN > 0
          ? 'Anunț publicat! (-$spent tokeni: anunț + $slotN Mystery Box)'
          : 'Anunț publicat! (-$spent tokeni)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } on SuspendedBusinessException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on InsufficientTokensException {
      if (!mounted) return;
      if (widget.isEditMode && _editExtraMysteryTokenCost() > 0) {
        final x = _editExtraMysteryTokenCost();
        _showPaymentSheet(
          tokensRequired: x,
          costHint:
              'Pentru cutiile Mystery Box noi îți trebuie cel puțin $x tokeni (${TokenCost.mysteryBoxSlot} tok ≈ 0,5 lei / cutie).',
        );
      } else {
        _showPaymentSheet(tokensRequired: _createOfferTotalTokens());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Eroare: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEdit = widget.isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editează anunțul' : 'Anunț nou'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEdit)
                StreamBuilder<TokenWallet?>(
                  stream: TokenService().walletStream,
                  builder: (context, snap) {
                    final balance = snap.data?.balance ?? 0;
                    final need = _createOfferTotalTokens();
                    final previewSlots = _previewMysterySlots();
                    final hasEnough = balance >= need;
                    final breakdown = previewSlots > 0
                        ? '${TokenCost.businessOffer} anunț + ${TokenCost.mysteryBoxSlotsTokenCost(previewSlots)} ($previewSlots × MB)'
                        : '${TokenCost.businessOffer} anunț';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasEnough
                            ? Colors.green.withAlpha(30)
                            : Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasEnough ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.toll_rounded,
                            color: hasEnough ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasEnough
                                  ? 'Sold: $balance tokeni  •  Total: $need ($breakdown)'
                                  : 'Sold insuficient: $balance tokeni (necesari: $need — $breakdown)',
                              style: TextStyle(
                                color: hasEnough ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (!isEdit) const SizedBox(height: 16),
              if (isEdit)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.outline.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Modificarea anunțului este gratuită, cu excepția suplimentării cutiilor Mystery Box: ${TokenCost.mysteryBoxSlot} tokeni per cutie (~0,5 lei, la fel ca la publicare). Numele și locația le actualizezi din setările cardului.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onPrimaryContainer,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isEdit) const SizedBox(height: 16),

              // Disclaimer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.policy_rounded, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ContentFilter.disclaimerText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Titlu anunț
              TextFormField(
                controller: _titleCtrl,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Titlul anunțului',
                  hintText: 'Ex: Meniu prânz 35 RON - paste artizanale',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 16),

              // Descriere
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Descriere',
                  hintText: 'Detalii despre ofertă, preț, program, condiții...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_rounded),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 16),

              // Link extern (opțional)
              TextFormField(
                controller: _linkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link extern (opțional)',
                  hintText: 'https://facebook.com/afacereaMea',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Telefon
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon (opțional)',
                  hintText: '07xx xxx xxx',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // WhatsApp
              TextFormField(
                controller: _whatsappCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp (opțional)',
                  hintText: '07xx xxx xxx',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Mystery Box pe hartă (plafon deschideri)
              TextFormField(
                controller: _mysteryBoxSlotsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cutii Mystery Box pe hartă (opțional)',
                  hintText: 'Ex: 50 — primii 50 la locație primesc oferta',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  helperText: isEdit
                      ? 'Lasă gol pentru nelimitat. Nu poți seta sub numărul deja deschis. Fiecare cutie nouă: ${TokenCost.mysteryBoxSlot} tok (~0,5 lei).'
                      : 'Lasă gol = fără plafon. Cu număr: ${TokenCost.mysteryBoxSlot} tokeni/cutie (~0,5 lei); pe hartă vezi „49 / 50”.',
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Flash
              Container(
                decoration: BoxDecoration(
                  color: _isFlash
                      ? const Color(0xFFFF6B35).withAlpha(20)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFlash
                        ? const Color(0xFFFF6B35)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: SwitchListTile(
                  value: _isFlash,
                  onChanged: (v) => setState(() => _isFlash = v),
                  secondary: Icon(
                    Icons.bolt_rounded,
                    color: _isFlash
                        ? const Color(0xFFFF6B35)
                        : Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  ),
                  title: Text(
                    'Ofertă Flash',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isFlash ? const Color(0xFFFF6B35) : null,
                    ),
                  ),
                  subtitle: const Text(
                    'Apare primul în feed, cu bordură portocalie. Ideal pentru promoții limitate.',
                    style: TextStyle(fontSize: 12),
                  ),
                  activeThumbColor: const Color(0xFFFF6B35),
                  activeTrackColor: const Color(0xFFFF6B35).withAlpha(80),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isEdit ? Icons.save_rounded : Icons.send_rounded),
                  label: Text(isEdit
                      ? 'Salvează modificările'
                      : 'Publică anunțul (-${_createOfferTotalTokens()} tokeni)'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment Sheet ─────────────────────────────────────────────────────────────

class _PurchaseOfferSheet extends StatelessWidget {
  final VoidCallback onGoToShop;
  /// Dacă e setat, afișează această sumă ca „necesar” (ex. total anunț+Mystery sau doar suplimentul la edit).
  final int? tokensRequired;
  final String? costHint;

  const _PurchaseOfferSheet({
    required this.onGoToShop,
    this.tokensRequired,
    this.costHint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final requiredTokens = tokensRequired ?? TokenCost.businessOffer;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colors.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Iconiță
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.toll_rounded, size: 32, color: colors.primary),
            ),
            const SizedBox(height: 16),

            Text(
              'Tokeni insuficienți',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<TokenWallet?>(
              stream: TokenService().walletStream,
              builder: (context, snap) {
                final balance = snap.data?.balance ?? 0;
                final hint = costHint;
                return Text(
                  'Sold actual: $balance tokeni\n'
                  'Necesar: $requiredTokens tokeni${hint != null ? '\n$hint' : ''}\n'
                  '(anunț 500 tok ≈ 5 lei; Mystery Box ${TokenCost.mysteryBoxSlot} tok ≈ 0,5 lei/cutie)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withAlpha(160),
                        height: 1.5,
                      ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Card ofertă
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primary.withAlpha(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '500 tokeni — 1 anunț',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Vizibil instant pentru persoanele din agendă',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '5 lei',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onGoToShop,
                icon: const Icon(Icons.shopping_cart_rounded),
                label: const Text('Cumpără tokeni'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
          ],
        ),
      ),
    );
  }
}
