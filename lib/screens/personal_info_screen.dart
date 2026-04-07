import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nabour_app/utils/content_filter.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); 
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  final _ageController = TextEditingController();
  final _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker(); // NOU
  
  RideCategory _selectedCategory = RideCategory.standard;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // NOU: Funcție pentru a alege și încărca imaginea
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image != null) {
      setState(() { _isLoading = true; });
      try {
        await _firestoreService.uploadProfileImage(File(image.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fotografia a fost actualizată!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) { setState(() { _isLoading = false; }); }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    // ── Filtru conținut ────────────────────────────────────────────────
    final nameCheck = ContentFilter.check(_nameController.text);
    if (!nameCheck.isClean) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nameCheck.message ?? 'Numele conține cuvinte inadecvate.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final currentRole = await _firestoreService.getUserRole();
      final isCurrentlyDriver = currentRole == UserRole.driver;

      if (isCurrentlyDriver) {
        // MODIFICAT: Adăugăm phoneNumber la salvarea profilului de șofer
        await _firestoreService.updateFullDriverProfile(
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(), // MODIFICAT
          licensePlate: _plateController.text.trim().toUpperCase(),
          category: _selectedCategory,
          carMake: _makeController.text.trim(),
          carModel: _modelController.text.trim(),
          carColor: _colorController.text.trim(),
          carYear: _yearController.text.trim(),
          age: _ageController.text.trim(),
        );
      } else {
        await _firestoreService.updatePassengerProfile(
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilul a fost actualizat!'), 
          backgroundColor: Colors.green
        ),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare: ${e.toString()}'), 
          backgroundColor: Colors.red
        ),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informații Cont'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getUserProfileStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final user = FirebaseAuth.instance.currentUser;
          final userData = snapshot.data?.data();
          final bool isDriver = userData?['role'] == 'driver';
          final photoURL = userData?['photoURL'] as String?; // NOU

          // Inițializăm controlerele o singură dată pentru a nu suprascrie textul în timpul editării
          if (_nameController.text.isEmpty) {
            _nameController.text = userData?['displayName'] ?? user?.displayName ?? '';
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = user?.email ?? 'N/A';
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = userData?['phoneNumber'] ?? '';
          }
          
          if(isDriver) {
            if(_plateController.text.isEmpty) _plateController.text = userData?['licensePlate'] ?? '';
            if(_makeController.text.isEmpty) _makeController.text = userData?['carMake'] ?? '';
            if(_modelController.text.isEmpty) _modelController.text = userData?['carModel'] ?? '';
            if(_colorController.text.isEmpty) _colorController.text = userData?['carColor'] ?? '';
            if(_yearController.text.isEmpty) _yearController.text = userData?['carYear'] ?? '';
            if(_ageController.text.isEmpty) _ageController.text = userData?['age'] ?? '';
            _selectedCategory = RideCategory.values.firstWhere(
              (e) => e.name == (userData?['driverCategory'] ?? 'standard'),
              orElse: () => RideCategory.standard,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NOU: UI pentru fotografia de profil
                  Center(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                            child: (photoURL == null || photoURL.isEmpty)
                                ? Icon(Icons.person, size: 60, color: Colors.grey.shade600)
                                : null,
                          ),
                          if (_isLoading)
                            const CircularProgressIndicator(),
                          if (!_isLoading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Date Generale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nume de Afișare Public', border: OutlineInputBorder()),
                    validator: (value) => (value ?? '').isEmpty ? 'Numele este obligatoriu.' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    enabled: false,
                  ),
                  const SizedBox(height: 20),
                   TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Număr de Telefon', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                     validator: (value) => (value ?? '').isEmpty ? 'Numărul de telefon este obligatoriu.' : null,
                  ),
                  
                  if (!isDriver) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withAlpha(75)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Informație',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Mașina ta apare pe hartă dacă ai completat datele necesare din meniul Mașina mea și este activat comutatorul șofer.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (isDriver) ...[
                    const Divider(height: 40),
                    const Text('Detalii Șofer Partener', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController, 
                      decoration: const InputDecoration(labelText: 'Vârstă', border: OutlineInputBorder()),
                      validator: isDriver ? (value) => (value ?? '').isEmpty ? 'Vârsta este obligatorie pentru șoferi.' : null : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _plateController, 
                      decoration: const InputDecoration(labelText: 'Număr Înmatriculare', border: OutlineInputBorder()),
                      validator: isDriver ? (value) => (value ?? '').isEmpty ? 'Numărul de înmatriculare este obligatoriu pentru șoferi.' : null : null,
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _makeController, 
                        decoration: const InputDecoration(labelText: 'Marcă', border: OutlineInputBorder()),
                        validator: isDriver ? (value) => (value ?? '').isEmpty ? 'Marca este obligatorie pentru șoferi.' : null : null,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(
                        controller: _modelController, 
                        decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                        validator: isDriver ? (value) => (value ?? '').isEmpty ? 'Modelul este obligatoriu pentru șoferi.' : null : null,
                      )),
                    ]),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _colorController, 
                        decoration: const InputDecoration(labelText: 'Culoare', border: OutlineInputBorder()),
                        validator: isDriver ? (value) => (value ?? '').isEmpty ? 'Culoarea este obligatorie pentru șoferi.' : null : null,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(
                        controller: _yearController, 
                        decoration: const InputDecoration(labelText: 'An Fabricație', border: OutlineInputBorder()),
                        validator: isDriver ? (value) => (value ?? '').isEmpty ? 'Anul de fabricație este obligatoriu pentru șoferi.' : null : null,
                      )),
                    ]),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<RideCategory>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoria Mașinii', border: OutlineInputBorder()),
                      items: RideCategory.values.map((c) => DropdownMenuItem(
                        value: c, 
                        child: Text(c.name[0].toUpperCase() + c.name.substring(1))
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ],

                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: Text(isDriver ? 'Salvează Modificările' : 'Salvează Informațiile'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
