import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/core/ui/app_feedback.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isSaving = false;

  bool _rideNotifications = true;
  bool _promoNotifications = true;
  bool _chatNotifications = true;
  bool _safetyAlerts = true;
  bool _appUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  String? get _uid => _auth.currentUser?.uid;

  Future<void> _loadPreferences() async {
    if (_uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('notificationPreferences')
          .doc('settings')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _rideNotifications = data['rideNotifications'] as bool? ?? true;
          _promoNotifications = data['promoNotifications'] as bool? ?? true;
          _chatNotifications = data['chatNotifications'] as bool? ?? true;
          _safetyAlerts = data['safetyAlerts'] as bool? ?? true;
          _appUpdates = data['appUpdates'] as bool? ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppFeedback.error(context, l10n.notifLoadError(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_uid == null) return;
    setState(() => _isSaving = true);
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('notificationPreferences')
          .doc('settings')
          .set({
        'rideNotifications': _rideNotifications,
        'promoNotifications': _promoNotifications,
        'chatNotifications': _chatNotifications,
        'safetyAlerts': _safetyAlerts,
        'appUpdates': _appUpdates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppFeedback.success(context, l10n.notifSavedSuccess);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppFeedback.error(context, l10n.notifSaveError(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onToggle(String key, bool value) async {
    setState(() {
      switch (key) {
        case 'rideNotifications':
          _rideNotifications = value;
        case 'promoNotifications':
          _promoNotifications = value;
        case 'chatNotifications':
          _chatNotifications = value;
        case 'safetyAlerts':
          _safetyAlerts = value;
        case 'appUpdates':
          _appUpdates = value;
      }
    });
    await _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationPreferences),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader(l10n.notifRideSection),
                _buildToggleTile(
                  icon: Icons.directions_car_outlined,
                  title: l10n.notifRideNotifications,
                  subtitle: l10n.notifRideNotificationsSubtitle,
                  value: _rideNotifications,
                  key: 'rideNotifications',
                ),
                const Divider(height: 1),
                _buildSectionHeader(l10n.notifCommunicationSection),
                _buildToggleTile(
                  icon: Icons.chat_bubble_outline,
                  title: l10n.notifChatMessages,
                  subtitle: l10n.notifChatMessagesSubtitle,
                  value: _chatNotifications,
                  key: 'chatNotifications',
                ),
                const Divider(height: 1),
                _buildSectionHeader(l10n.notifMarketingSection),
                _buildToggleTile(
                  icon: Icons.local_offer_outlined,
                  title: l10n.notifPromoOffers,
                  subtitle: l10n.notifPromoOffersSubtitle,
                  value: _promoNotifications,
                  key: 'promoNotifications',
                ),
                _buildToggleTile(
                  icon: Icons.system_update_outlined,
                  title: l10n.notifAppUpdates,
                  subtitle: l10n.notifAppUpdatesSubtitle,
                  value: _appUpdates,
                  key: 'appUpdates',
                ),
                const Divider(height: 1),
                _buildSectionHeader(l10n.notifSafetySection),
                _buildToggleTile(
                  icon: Icons.shield_outlined,
                  title: l10n.notifSafetyAlerts,
                  subtitle: l10n.notifSafetyAlertsSubtitle,
                  value: _safetyAlerts,
                  key: 'safetyAlerts',
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required String key,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _isSaving ? null : (v) => _onToggle(key, v),
    );
  }
}
