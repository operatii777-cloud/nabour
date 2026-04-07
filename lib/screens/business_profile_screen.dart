import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/user_model.dart';
import 'package:nabour_app/utils/logger.dart';

/// Feature: Business profile / work receipt — allows users to set up a
/// corporate account for expense tracking and business receipts.
class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isBusinessAccount = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists || !mounted) return;
      final user = UserModel.fromFirestore(doc);
      setState(() {
        _isBusinessAccount = user.isBusinessAccount;
        _businessNameController.text = user.businessName ?? '';
        _taxIdController.text = user.businessTaxId ?? '';
        _addressController.text = user.businessAddress ?? '';
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading business profile: $e', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'isBusinessAccount': _isBusinessAccount,
        'businessName': _isBusinessAccount ? _businessNameController.text.trim() : null,
        'businessTaxId': _isBusinessAccount ? _taxIdController.text.trim() : null,
        'businessAddress': _isBusinessAccount ? _addressController.text.trim() : null,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil de business actualizat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error saving business profile: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Eroare: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Business'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvează', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Cont Business',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Activează pentru a genera chitanțe cu datele companiei, '
                              'utile pentru decontarea cheltuielilor.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              value: _isBusinessAccount,
                              onChanged: (v) => setState(() => _isBusinessAccount = v),
                              title: const Text('Activează cont business'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isBusinessAccount) ...[
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date companie',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _businessNameController,
                                decoration: InputDecoration(
                                  labelText: 'Denumire companie *',
                                  prefixIcon: const Icon(Icons.business_center),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Câmp obligatoriu' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _taxIdController,
                                decoration: InputDecoration(
                                  labelText: 'CIF / Cod fiscal',
                                  prefixIcon: const Icon(Icons.numbers),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final trimmed = v.trim();
                                  if (!RegExp(r'^\d+$').hasMatch(trimmed) ||
                                      trimmed.length < 2 ||
                                      trimmed.length > 10) {
                                    return 'CIF invalid (2-10 cifre)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: 'Adresă sediu',
                                  prefixIcon: const Icon(Icons.location_on),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Chitanțele generate vor include datele companiei tale pentru decontare. '
                                  'Poți descărca PDF-ul după finalizarea fiecărei curse.',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
