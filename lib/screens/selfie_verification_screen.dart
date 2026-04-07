import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nabour_app/models/user_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Feature: Selfie identity verification — allows users to submit a selfie
/// for identity verification. Status: pending → verified/rejected (reviewed by admin).
class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() => _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  String? _selfieVerificationStatus;
  String? _selfieImageUrl;
  File? _selectedSelfieFile;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists || !mounted) return;
      final user = UserModel.fromFirestore(doc);
      setState(() {
        _selfieVerificationStatus = user.selfieVerificationStatus;
        _selfieImageUrl = doc.data()?['selfieImageUrl'];
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading verification status: $e', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _selectedSelfieFile = File(image.path));
      }
    } catch (e) {
      Logger.error('Error taking selfie: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la capturarea selfie: $e')),
        );
      }
    }
  }

  Future<void> _submitSelfie() async {
    if (_selectedSelfieFile == null) return;
    setState(() => _isSubmitting = true);
    try {
      await _firestoreService.submitSelfieVerification(_selectedSelfieFile!);
      if (mounted) {
        setState(() {
          _selfieVerificationStatus = 'pending';
          _selectedSelfieFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Selfie trimis spre verificare. Vei fi notificat în 24h.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error submitting selfie: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Eroare: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificare identitate')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 24),
                  _buildInstructionsCard(),
                  const SizedBox(height: 24),
                  _buildSelfiePreview(),
                  const SizedBox(height: 24),
                  if (_selfieVerificationStatus != 'verified') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _takeSelfie,
                        icon: const Icon(Icons.camera_front),
                        label: const Text('Fă un selfie'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedSelfieFile != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitSelfie,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload),
                          label: Text(_isSubmitting ? 'Se trimite...' : 'Trimite pentru verificare'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _selfieVerificationStatus;
    if (status == null) {
      return _statusCard(
        Icons.shield_outlined,
        Colors.grey,
        'Neverificat',
        'Identitatea ta nu a fost verificată încă.',
      );
    }
    switch (status) {
      case 'pending':
        return _statusCard(
          Icons.hourglass_top,
          Colors.orange,
          'În așteptare',
          'Selfie-ul tău este în curs de verificare. Vei fi notificat în curând.',
        );
      case 'verified':
        return _statusCard(
          Icons.verified_user,
          Colors.green,
          'Verificat ✓',
          'Identitatea ta a fost verificată cu succes.',
        );
      case 'rejected':
        return _statusCard(
          Icons.cancel,
          Colors.red,
          'Respins',
          'Verificarea a fost respinsă. Te rugăm să trimiți un selfie mai clar.',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _statusCard(IconData icon, Color color, String title, String message) {
    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: color.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Instrucțiuni',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            _InstructionItem(icon: Icons.light_mode, text: 'Asigură-te că ai lumină bună pe față'),
            _InstructionItem(icon: Icons.face, text: 'Privește direct spre cameră'),
            _InstructionItem(icon: Icons.no_photography, text: 'Nu purta ochelari de soare sau mască'),
            _InstructionItem(icon: Icons.high_quality, text: 'Asigură-te că imaginea este clară'),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfiePreview() {
    if (_selectedSelfieFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedSelfieFile!,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    if (_selfieImageUrl != null) {
      return Column(
        children: [
          const Text(
            'Selfie trimis anterior:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _selfieImageUrl!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
            ),
          ),
        ],
      );
    }
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_front, size: 60, color: Colors.grey),
          SizedBox(height: 8),
          Text('Nicio fotografie selectată', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
