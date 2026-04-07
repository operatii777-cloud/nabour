import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nabour_app/utils/logger.dart';

class DriverApplicationScreen extends StatefulWidget {
  const DriverApplicationScreen({super.key});

  @override
  State<DriverApplicationScreen> createState() =>
      _DriverApplicationScreenState();
}

class _DriverApplicationScreenState extends State<DriverApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();

  String? _selectedCarClass;
  static const List<String> _carClasses = [
    'Standard',
    'Eco',
    'Confort',
    'Utilitară',
    'SUV',
    'Premium',
  ];

  File? _carPhoto;
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _brandController.text = data['carBrand'] ?? '';
        _modelController.text = data['carModel'] ?? '';
        _plateController.text = data['licensePlate'] ?? '';
        final savedClass = data['carClass'] as String?;
        if (savedClass != null && _carClasses.contains(savedClass)) {
          _selectedCarClass = savedClass;
        }
      }
    } catch (e) {
      Logger.error('Error loading car data: $e', error: e);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool _) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 600,
      );
      if (picked == null) return;
      setState(() {
        _carPhoto = File(picked.path);
      });
    } catch (e) {
      Logger.error('Error picking image: $e', error: e);
    }
  }

  Future<String?> _uploadPhoto(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      Logger.error('Error uploading photo: $e', error: e);
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Neautentificat');

      String? carPhotoUrl;

      if (_carPhoto != null) {
        carPhotoUrl =
            await _uploadPhoto(_carPhoto!, 'driver_photos/$uid/car.jpg');
      }

      await FirebaseFirestore.instance
          .collection('driver_applications')
          .doc(uid)
          .set({
        'carBrand': _brandController.text.trim(),
        'carModel': _modelController.text.trim(),
        'licensePlate':
            _plateController.text.trim().toUpperCase(),
        'carClass': _selectedCarClass,
        if (carPhotoUrl != null) 'carPhotoUrl': carPhotoUrl,
        'status': 'approved',
        'submittedAt': FieldValue.serverTimestamp(),
        'uid': uid,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'driver',
        'carBrand': _brandController.text.trim(),
        'carModel': _modelController.text.trim(),
        'licensePlate':
            _plateController.text.trim().toUpperCase(),
        'carClass': _selectedCarClass,
        if (carPhotoUrl != null) 'carPhotoUrl': carPhotoUrl,
      }, SetOptions(merge: true));

      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      Logger.error('Driver registration error: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mașina mea'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submitted
              ? _buildSuccess(theme)
              : _buildForm(theme),
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Ești înregistrat!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Contul tău de șofer Nabour este activ. '
              'Poți activa modul șofer din hartă.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Înapoi',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_rounded,
                      color: Color(0xFF7C3AED), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Înregistrare simplă',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          'Marca, modelul și numărul de înmatriculare — atât. '
                          'Pozele sunt opționale.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Date mașină ────────────────────────────────────────
            Text('Detalii mașină',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            _buildField(
              controller: _brandController,
              label: 'Marcă *',
              hint: 'ex: Dacia, Volkswagen, BMW',
              icon: Icons.directions_car_outlined,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _modelController,
              label: 'Model *',
              hint: 'ex: Logan, Golf, Seria 3',
              icon: Icons.drive_eta_outlined,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _plateController,
              label: 'Număr înmatriculare *',
              hint: 'ex: B 123 ABC',
              icon: Icons.pin_outlined,
              capitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9 ]')),
                LengthLimitingTextInputFormatter(10),
              ],
            ),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCarClass,
              decoration: InputDecoration(
                labelText: 'Clasa mașinii *',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _carClasses
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCarClass = v),
              validator: (v) =>
                  v == null ? 'Selectează clasa mașinii' : null,
            ),

            const SizedBox(height: 28),

            // ── Fotografie mașină (opțional) ──────────────────────────
            Text('Fotografie mașină (opțional)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'O poză cu mașina ajută vecinii să te recunoască mai ușor.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),

            _buildPhotoPicker(
              label: 'Mașina ta',
              icon: Icons.directions_car_rounded,
              photo: _carPhoto,
              onTap: () => _pickImage(true),
            ),

            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Înregistrează-mă ca șofer',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Nu există taxe, comisioane sau verificări de documente.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (v) {
        if (label.endsWith('*') && (v == null || v.trim().isEmpty)) {
          return 'Câmp obligatoriu';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoPicker({
    required String label,
    required IconData icon,
    required File? photo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: photo != null
                ? const Color(0xFF7C3AED)
                : Colors.grey.shade300,
            width: photo != null ? 2 : 1,
          ),
        ),
        child: photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(photo, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adaugă foto',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
