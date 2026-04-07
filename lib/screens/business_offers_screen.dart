import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/models/business_offer_model.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/services/business_service.dart';
import 'package:nabour_app/services/offer_preferences_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/utils/layout_text_scale.dart';
import 'package:nabour_app/l10n/app_localizations.dart';

class BusinessOffersScreen extends StatefulWidget {
  const BusinessOffersScreen({super.key});

  @override
  State<BusinessOffersScreen> createState() => _BusinessOffersScreenState();
}

class _BusinessOffersScreenState extends State<BusinessOffersScreen> {
  List<BusinessOffer>? _offers;
  bool _isLoading = true;
  String? _error;
  final _prefs = OfferPreferencesService();
  BusinessCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _prefs.init();
    await _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Permisiunea de locație este dezactivată. Activează-o din setări.';
          _isLoading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final offers = await BusinessService().getNearbyOffers(
        userLat: pos.latitude,
        userLng: pos.longitude,
      );

      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Eroare la încărcarea ofertelor: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<BusinessOffer> get _baseVisibleOffers {
    final all = _offers ?? [];
    return all
        .where((o) =>
            !_prefs.isOfferHidden(o.id) && !_prefs.isBusinessHidden(o.businessId))
        .toList();
  }

  List<BusinessOffer> get _visibleOffers {
    final base = _baseVisibleOffers;
    if (_selectedCategory == null) return base;
    return base.where((o) => o.businessCategory == _selectedCategory).toList();
  }

  List<BusinessCategory> get _availableCategories {
    final present = _baseVisibleOffers.map((o) => o.businessCategory).toSet();
    final ordered = <BusinessCategory>[
      ...BusinessCategory.selectable,
      for (final c in present)
        if (!BusinessCategory.selectable.contains(c)) c,
    ];
    return ordered;
  }

  Future<void> _hideOffer(BusinessOffer offer) async {
    await _prefs.hideOffer(offer.id, offer.title);
    if (mounted) setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anunț ascuns.'),
          action: SnackBarAction(
            label: 'Anulează',
            onPressed: () async {
              await _prefs.unhideOffer(offer.id);
              if (mounted) setState(() {});
            },
          ),
        ),
      );
    }
  }

  Future<void> _hideBusiness(BusinessOffer offer) async {
    await _prefs.hideBusiness(offer.businessId, offer.businessName);
    if (mounted) setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toate anunțurile de la „${offer.businessName}" ascunse.'),
          action: SnackBarAction(
            label: 'Anulează',
            onPressed: () async {
              await _prefs.unhideBusiness(offer.businessId);
              if (mounted) setState(() {});
            },
          ),
        ),
      );
    }
  }

  void _showHiddenManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HiddenManagerSheet(
        prefs: _prefs,
        onChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hiddenCount = _prefs.hiddenCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oferte din cartier'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        actions: [
          if (hiddenCount > 0)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  tooltip: 'Filtre active',
                  onPressed: _showHiddenManager,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$hiddenCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reîncarcă',
            onPressed: _loadOffers,
          ),
        ],
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(ColorScheme colors) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return const _SkeletonFeed();

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadOffers,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Încearcă din nou'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = _visibleOffers;
    final baseVisible = _baseVisibleOffers;
    final categories = _availableCategories;
    final totalLoaded = (_offers ?? []).length;
    final hiddenCount = totalLoaded - baseVisible.length;
    final categoryFilteredOut =
        _selectedCategory == null ? 0 : baseVisible.length - visible.length;

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined,
                size: 72, color: colors.onSurface.withAlpha(80)),
            const SizedBox(height: 16),
            Text(
              hiddenCount > 0
                  ? 'Toate ofertele sunt ascunse'
                  : categoryFilteredOut > 0
                      ? l10n.businessOffersNoOffersInSelectedCategory
                      : l10n.businessOffersNoOffersInArea,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurface.withAlpha(120),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hiddenCount > 0
                  ? 'Ai $hiddenCount ${hiddenCount == 1 ? 'filtru activ' : 'filtre active'}.'
                  : categoryFilteredOut > 0
                      ? l10n.businessOffersTryAnotherCategory
                      : l10n.businessOffersNoNearbyOffers,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withAlpha(100),
                  ),
              textAlign: TextAlign.center,
            ),
            if (hiddenCount > 0 || categoryFilteredOut > 0) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: hiddenCount > 0
                    ? _showHiddenManager
                    : () => setState(() => _selectedCategory = null),
                icon: Icon(
                  hiddenCount > 0
                      ? Icons.filter_list_rounded
                      : Icons.restart_alt_rounded,
                ),
                label: Text(
                  hiddenCount > 0
                      ? l10n.businessOffersManageFilters
                      : l10n.businessOffersResetCategory,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOffers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount:
            visible.length + (hiddenCount > 0 ? 1 : 0) + (categories.isNotEmpty ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (categories.isNotEmpty && i == 0) {
            return _CategoryFilterBar(
              categories: categories,
              selected: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value),
            );
          }
          final dataIndex = categories.isNotEmpty ? i - 1 : i;
          if (dataIndex == visible.length) {
            // Banner filtre active la finalul listei
            return _FilterBanner(
              hiddenCount: hiddenCount,
              onManage: _showHiddenManager,
            );
          }
          return _OfferFeedCard(
            offer: visible[dataIndex],
            onHideOffer: () => _hideOffer(visible[dataIndex]),
            onHideBusiness: () => _hideBusiness(visible[dataIndex]),
          );
        },
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<BusinessCategory> categories;
  final BusinessCategory? selected;
  final ValueChanged<BusinessCategory?> onChanged;

  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.businessOffersAllCategories),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  '${cat.emoji} ${cat.displayNameForLanguage(lang)}',
                ),
                selected: selected == cat,
                onSelected: (_) => onChanged(cat),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner filtre active ───────────────────────────────────────────────────────

class _FilterBanner extends StatelessWidget {
  final int hiddenCount;
  final VoidCallback onManage;
  const _FilterBanner({required this.hiddenCount, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSmall = MediaQuery.of(context).size.width < 360;
    return GestureDetector(
      onTap: onManage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outline.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_off_rounded,
                size: 18, color: colors.onSurface.withAlpha(150)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$hiddenCount ${hiddenCount == 1 ? 'ofertă ascunsă' : 'oferte ascunse'} din filtrele tale.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withAlpha(150),
                    ),
              ),
            ),
            if (!isSmall)
              Text(
                'Gestionează',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            if (!isSmall) const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Sheet gestionare ascunse ──────────────────────────────────────────────────

class _HiddenManagerSheet extends StatefulWidget {
  final OfferPreferencesService prefs;
  final VoidCallback onChanged;
  const _HiddenManagerSheet({required this.prefs, required this.onChanged});

  @override
  State<_HiddenManagerSheet> createState() => _HiddenManagerSheetState();
}

class _HiddenManagerSheetState extends State<_HiddenManagerSheet> {
  Future<void> _restore(Future<void> Function() action) async {
    await action();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bizIds = widget.prefs.hiddenBizIds.toList();
    final offerIds = widget.prefs.hiddenOfferIds.toList();
    final hasAny = bizIds.isNotEmpty || offerIds.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtrele mele',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (hasAny)
                  TextButton(
                    onPressed: () async {
                      await widget.prefs.clearAll();
                      widget.onChanged();
                      setState(() {});
                    },
                    child: Text(
                      'Resetează tot',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Conținut
          Expanded(
            child: !hasAny
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 48,
                            color: colors.onSurface.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(
                          'Niciun filtru activ.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: colors.onSurface.withAlpha(120)),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (bizIds.isNotEmpty) ...[
                        const _SectionLabel('Comercianți ascunși'),
                        ...bizIds.map((id) {
                          final name =
                              widget.prefs.hiddenBizNames[id] ?? id;
                          return _HiddenTile(
                            icon: Icons.storefront_rounded,
                            label: name,
                            onRestore: () => _restore(
                                () => widget.prefs.unhideBusiness(id)),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                      if (offerIds.isNotEmpty) ...[
                        const _SectionLabel('Anunțuri ascunse'),
                        ...offerIds.map((id) {
                          final title =
                              widget.prefs.hiddenOfferTitles[id] ?? id;
                          return _HiddenTile(
                            icon: Icons.campaign_rounded,
                            label: title,
                            onRestore: () =>
                                _restore(() => widget.prefs.unhideOffer(id)),
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _HiddenTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onRestore;
  const _HiddenTile(
      {required this.icon, required this.label, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colors.onSurface.withAlpha(150), size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: TextButton(
        onPressed: onRestore,
        child: const Text('Restaurează'),
      ),
    );
  }
}

// ── Skeleton Loading ──────────────────────────────────────────────────────────

class _SkeletonFeed extends StatefulWidget {
  const _SkeletonFeed();

  @override
  State<_SkeletonFeed> createState() => _SkeletonFeedState();
}

class _SkeletonFeedState extends State<_SkeletonFeed>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final base = Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFE8E8E8);
        final highlight = Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF3A3A3A)
            : const Color(0xFFF5F5F5);
        final color = Color.lerp(base, highlight, _anim.value)!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => _SkeletonCard(color: color),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Color color;
  const _SkeletonCard({required this.color});

  Widget _box(double w, double h, {double radius = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withAlpha(80),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _box(36, 36, radius: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(120, 12),
                    const SizedBox(height: 6),
                    _box(80, 10),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(200, 14),
                const SizedBox(height: 8),
                _box(double.infinity, 10),
                const SizedBox(height: 4),
                _box(double.infinity, 10),
                const SizedBox(height: 4),
                _box(140, 10),
                const SizedBox(height: 14),
                Row(children: [
                  _box(80, 32, radius: 16),
                  const SizedBox(width: 8),
                  _box(100, 32, radius: 16),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed Card ────────────────────────────────────────────────────────────────

class _OfferFeedCard extends StatefulWidget {
  final BusinessOffer offer;
  final VoidCallback onHideOffer;
  final VoidCallback onHideBusiness;

  const _OfferFeedCard({
    required this.offer,
    required this.onHideOffer,
    required this.onHideBusiness,
  });

  @override
  State<_OfferFeedCard> createState() => _OfferFeedCardState();
}

class _OfferFeedCardState extends State<_OfferFeedCard> {
  static final Set<String> _countedThisSession = {};

  @override
  void initState() {
    super.initState();
    final id = widget.offer.id;
    if (_countedThisSession.add(id)) {
      BusinessService().incrementViews(id);
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    HapticFeedback.lightImpact();
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String number, String title) async {
    var cleaned = number.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) {
      final waLink = RegExp(r'wa\.me/(\d+)', caseSensitive: false).firstMatch(number);
      if (waLink != null) cleaned = waLink.group(1)!;
    }
    if (cleaned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Număr WhatsApp indisponibil.')),
      );
      return;
    }
    // România: 07xxxxxxxx (10 cifre, începe cu 0) → wa.me așteaptă 40…
    if (cleaned.length == 10 && cleaned.startsWith('0')) {
      cleaned = '40${cleaned.substring(1)}';
    }

    final message = Uri.encodeComponent(
      'Salut! Am văzut oferta ta „$title" pe Nabour și aș vrea mai multe detalii! 🧋',
    );
    final webUri = Uri.parse('https://wa.me/$cleaned?text=$message');
    final appUri = Uri.parse('whatsapp://send?phone=$cleaned&text=$message');

    Future<bool> tryOpen(Uri uri) async {
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }

    if (await tryOpen(webUri)) return;
    if (await tryOpen(appUri)) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nu s-a putut deschide WhatsApp. Verifică dacă aplicația este instalată.',
          ),
        ),
      );
    }
  }

  void _showMenu(BuildContext context) {
    final offer = widget.offer;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_rounded),
              title: const Text('Ascunde acest anunț'),
              subtitle: Text(
                offer.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                widget.onHideOffer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.store_mall_directory_rounded),
              title: Text('Ascunde toate anunțurile de la „${offer.businessName}"'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                widget.onHideBusiness();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final offer = widget.offer;
    final ls = layoutScaleFactor(context);
    final lang = Localizations.localeOf(context).languageCode;
    final dateStr =
        DateFormat('dd MMM, HH:mm', 'ro_RO').format(offer.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: offer.isFlash
                ? Colors.orange.withAlpha(40)
                : colors.shadow.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: offer.isFlash
              ? Colors.orange.withAlpha(100)
              : colors.onSurface.withAlpha(15),
          width: offer.isFlash ? 1.5 : 0.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header afacere
              Container(
                padding: scaledFromLTRB(16, 14, 4, 52, ls),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: offer.isFlash
                        ? [Colors.orange.shade50, Colors.white]
                        : [colors.primaryContainer, colors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 6 * ls),
                      child: Container(
                        padding: EdgeInsets.all(8 * ls),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withAlpha(40),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          offer.businessCategory.emoji,
                          style: TextStyle(
                            fontSize:
                                MediaQuery.textScalerOf(context).scale(18),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * ls),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            offer.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  offer.businessCategory.displayNameForLanguage(lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              if (offer.distanceKm != null) ...[
                                Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: colors.onSurface.withAlpha(60),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  '📍 ~${offer.distanceKm!.toStringAsFixed(1)} km',
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.redAccent.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Data + views — Flexible evită overflow pe telefoane înguste (ex. MIUI 1080px)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dateStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.onSurface.withAlpha(120),
                                  ),
                            ),
                            if (offer.viewsCount > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 11,
                                    color: colors.onSurface.withAlpha(100),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${offer.viewsCount}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: colors.onSurface
                                              .withAlpha(100),
                                        ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Meniu ⋮ — touch target redus pentru lățime
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colors.onSurface.withAlpha(120),
                        size: 22,
                      ),
                      tooltip: 'Opțiuni',
                      onPressed: () => _showMenu(context),
                    ),
                  ],
                ),
              ),

              // Conținut
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withAlpha(180),
                            height: 1.4,
                          ),
                    ),

                    if (offer.link != null ||
                        offer.phone != null ||
                        offer.whatsapp != null) ...[
                      const SizedBox(height: 18),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (offer.phone != null)
                              _ActionButton(
                                icon: Icons.phone_rounded,
                                label: 'Sună',
                                color: Colors.green.shade600,
                                onTap: () => _call(offer.phone!),
                              ),
                            if (offer.whatsapp != null) ...[
                              const SizedBox(width: 8),
                              _ActionButton(
                                icon: Icons.message_rounded,
                                label: 'WhatsApp',
                                color: Colors.teal.shade500,
                                onTap: () =>
                                    _whatsapp(offer.whatsapp!, offer.title),
                              ),
                            ],
                            if (offer.link != null) ...[
                              const SizedBox(width: 8),
                              _ActionButton(
                                icon: Icons.open_in_new_rounded,
                                label: 'Vezi detaliile',
                                color: colors.primary,
                                isPrimary: true,
                                onTap: () => _launch(offer.link!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            ),
          ),

          // Flash ribbon
          if (offer.isFlash)
            Positioned(
              right: -30,
              top: 15,
              child: Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '⚡ FLASH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
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

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? color : color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? Colors.transparent : color.withAlpha(80),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: isPrimary ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
