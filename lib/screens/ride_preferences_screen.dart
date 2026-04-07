import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_preferences_model.dart';
import 'package:nabour_app/widgets/ride_preferences_widget.dart';
import 'package:nabour_app/utils/logger.dart';

/// Ecran pentru setarea preferințelor de cursă (Uber-like)
class RidePreferencesScreen extends StatefulWidget {
  const RidePreferencesScreen({super.key});

  @override
  State<RidePreferencesScreen> createState() => _RidePreferencesScreenState();
}

class _RidePreferencesScreenState extends State<RidePreferencesScreen> {
  RidePreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference? get _prefDoc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('ridePreferences')
        .doc('settings');
  }

  Future<void> _loadPreferences() async {
    try {
      final doc = _prefDoc;
      if (doc != null) {
        final snap = await doc.get();
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>?;
          if (data != null && mounted) {
            setState(() {
              _preferences = RidePreferences.fromMap(data);
              _isLoading = false;
            });
            return;
          }
        }
      }
      setState(() {
        _preferences = const RidePreferences();
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading preferences: $e', error: e);
      setState(() {
        _preferences = const RidePreferences();
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences(RidePreferences preferences) async {
    try {
      final doc = _prefDoc;
      if (doc != null) {
        await doc.set({
          ...preferences.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      setState(() => _preferences = preferences);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferințele au fost salvate'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error saving preferences: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la salvare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preferințe Cursă')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferințe Cursă'),
      ),
      body: RidePreferencesWidget(
        initialPreferences: _preferences,
        onPreferencesChanged: _savePreferences,
      ),
    );
  }
}

