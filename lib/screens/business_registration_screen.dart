import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/services/business_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/screens/business_dashboard_screen.dart';
import 'package:nabour_app/utils/content_filter.dart';
import 'package:nabour_app/utils/layout_text_scale.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  BusinessCategory _selectedCategory = BusinessCategory.restaurant;
  bool _isLoading = false;
  bool _isLocating = false;
  double? _lat;
  double? _lng;

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
            const SnackBar(content: Text('Permisiunea de locație este dezactivată.')),
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
          content: Text('Te rugăm să detectezi locația afacerii înainte de a continua.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ── Filtru conținut ────────────────────────────────────────────────────
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
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final profile = BusinessProfile(
        id: '',
        userId: uid,
        businessName: _nameCtrl.text.trim(),
        category: _selectedCategory,
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        latitude: _lat!,
        longitude: _lng!,
        createdAt: DateTime.now(),
      );

      final id = await BusinessService().registerBusiness(profile);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BusinessDashboardScreen(profileId: id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la înregistrare: $e'), backgroundColor: Colors.red),
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
        title: const Text('Înregistrare Afacere'),
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store_rounded, color: colors.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Înscrie-ți afacerea pe Nabour',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ajunge la clienții din cartier. 10 tokeni/anunț.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onPrimaryContainer.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categorie
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

              // Nume afacere
              _buildField(
                controller: _nameCtrl,
                label: 'Numele afacerii',
                icon: Icons.business_rounded,
                validator: (v) => v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 16),

              // Adresă
              _buildField(
                controller: _addressCtrl,
                label: 'Adresa (stradă, număr, oraș)',
                icon: Icons.location_on_rounded,
                validator: (v) => v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 16),

              // Locație GPS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLocating ? null : _detectLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(_lat != null
                          ? 'Locație detectată'
                          : 'Detectează locația afacerii'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _lat != null ? Colors.green : colors.primary,
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

              // Telefon
              _buildField(
                controller: _phoneCtrl,
                label: 'Telefon',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 16),

              // WhatsApp (opțional)
              _buildField(
                controller: _whatsappCtrl,
                label: 'WhatsApp (opțional)',
                icon: Icons.message_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Website (opțional)
              _buildField(
                controller: _websiteCtrl,
                label: 'Website / Facebook (opțional)',
                icon: Icons.link_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Descriere
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
                validator: (v) => v!.trim().isEmpty ? 'Câmp obligatoriu' : null,
              ),
              const SizedBox(height: 24),

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
                      : const Icon(Icons.check_rounded),
                  label: const Text('Înregistrează afacerea'),
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
