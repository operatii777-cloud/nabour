import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/services/business_service.dart';
import 'package:nabour_app/utils/content_filter.dart';
import 'package:nabour_app/utils/layout_text_scale.dart';

/// Setări card afacere: nume, categorie, adresă, contact, locație — se propagă pe anunțuri.
class BusinessProfileEditScreen extends StatefulWidget {
  final BusinessProfile profile;

  const BusinessProfileEditScreen({super.key, required this.profile});

  @override
  State<BusinessProfileEditScreen> createState() =>
      _BusinessProfileEditScreenState();
}

class _BusinessProfileEditScreenState extends State<BusinessProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late BusinessCategory _selectedCategory;
  bool _isLoading = false;
  bool _isLocating = false;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl.text = p.businessName;
    _addressCtrl.text = p.address;
    _phoneCtrl.text = p.phone;
    _websiteCtrl.text = p.website ?? '';
    _whatsappCtrl.text = p.whatsapp ?? '';
    _descCtrl.text = p.description;
    _selectedCategory = p.category;
    _lat = p.latitude;
    _lng = p.longitude;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _whatsappCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Permisiunea de locație este dezactivată.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Locație detectată cu succes.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la detectarea locației: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Te rugăm să detectezi locația afacerii înainte de a continua.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final descCheck = ContentFilter.check(_descCtrl.text);
    final nameCheck = ContentFilter.check(_nameCtrl.text);
    if (!descCheck.isClean || !nameCheck.isClean) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (!nameCheck.isClean ? nameCheck.message : descCheck.message) ??
                'Conținut inadecvat detectat.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final p = widget.profile;
      final updated = BusinessProfile(
        id: p.id,
        userId: p.userId,
        businessName: _nameCtrl.text.trim(),
        category: _selectedCategory,
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isEmpty
            ? null
            : _websiteCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim().isEmpty
            ? null
            : _whatsappCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        latitude: _lat!,
        longitude: _lng!,
        createdAt: p.createdAt,
        isActive: p.isActive,
        isSuspended: p.isSuspended,
        subscriptionExpiresAt: p.subscriptionExpiresAt,
      );

      await BusinessService().updateProfileWithOfferSync(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cardul afacerii a fost actualizat.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
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
    final ls = layoutScaleFactor(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card afacere & setări'),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: colors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Modificările se reflectă în cardul din „Oferte din cartier” și în toate anunțurile tale active.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onPrimaryContainer.withAlpha(220),
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20 * ls),
              Text('Categorie', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<BusinessCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category_rounded),
                  contentPadding: scaledFromLTRB(12, 16, 12, 28, ls),
                ),
                items: BusinessCategory.selectable.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text('${cat.emoji}  ${cat.displayNameForLanguage(lang)}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              SizedBox(height: 20 * ls),
              _buildField(
                controller: _nameCtrl,
                label: 'Numele afacerii',
                icon: Icons.business_rounded,
                validator: (v) => v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _addressCtrl,
                label: 'Adresa (stradă, număr, oraș)',
                icon: Icons.location_on_rounded,
                validator: (v) => v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLocating ? null : _detectLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(_lat != null
                          ? 'Actualizează locația GPS'
                          : 'Detectează locația afacerii'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            _lat != null ? Colors.green : colors.primary,
                        side: BorderSide(
                          color: _lat != null ? Colors.green : colors.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_lat != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _phoneCtrl,
                label: 'Telefon',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _whatsappCtrl,
                label: 'WhatsApp (opțional)',
                icon: Icons.message_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _websiteCtrl,
                label: 'Website / Facebook (opțional)',
                icon: Icons.link_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Descriere scurtă',
                  hintText: 'Ce oferă afacerea ta clienților din cartier?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_rounded),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 24),
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
                      : const Icon(Icons.save_rounded),
                  label: const Text('Salvează modificările'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}
