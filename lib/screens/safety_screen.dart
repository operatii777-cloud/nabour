import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/safety_preferences.dart';
import '../l10n/app_localizations.dart';
import '../core/haptics/haptic_service.dart';
import '../features/safe_ride/safe_ride_service.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen>
    with TickerProviderStateMixin {
  List<TrustedContact> _contacts = const [];
  bool _isLoadingContacts = true;
  bool _sosActive = false;
  bool _isSharingTrip = false;
  String? _activeRideId;
  String? _activeRideDestination;
  String? _safeRideTrackingUrl;
  bool _isCreatingSafeRide = false;

  late AnimationController _sosController;
  late Animation<double> _sosPulse;

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _sosPulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _sosController, curve: Curves.easeInOut),
    );
    _loadContacts();
    _checkActiveRide();
  }

  @override
  void dispose() {
    _sosController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);
    final contacts = await SafetyPreferences.loadTrustedContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _isLoadingContacts = false;
    });
  }

  Future<void> _checkActiveRide() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('rides')
          .where('passengerId', isEqualTo: uid)
          .where('status', whereIn: ['accepted', 'arrived', 'in_progress'])
          .limit(1)
          .get();
      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        setState(() {
          _activeRideId = snap.docs.first.id;
          _activeRideDestination = data['destination'] as String?;
        });
      }
    } catch (_) {}
  }

  // ── SOS ─────────────────────────────────────────────────────────────────────

  Future<void> _triggerSOS() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(l10n.safety_emergencyAssistanceButton,
                style: const TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(l10n.safety_emergencyAssistanceButtonDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.safety_sosButtonLabel,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _sosActive = true);
    unawaited(HapticService.instance.sos());

    // 1. Get current position
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    final locationText = position != null
        ? 'https://maps.google.com/?q=${position.latitude},${position.longitude}'
        : l10n.safety_locationUnavailable;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? l10n.safety_defaultNabourUser;

    // 2. Log emergency to Firestore
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('emergency_alerts').add({
          'userId': uid,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'rideId': _activeRideId,
          'status': 'active',
        });
      } catch (_) {}
    }

    // 3. Send SMS to all trusted contacts
    if (_contacts.isNotEmpty) {
      final smsBody = Uri.encodeComponent(
        l10n.safety_emergencySmsBody(userName, locationText),
      );
      for (final contact in _contacts) {
        final smsUri = Uri.parse('sms:${contact.phoneNumber}?body=$smsBody');
        try {
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (_) {}
      }
    }

    // 4. Call 112
    final callUri = Uri.parse('tel:112');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri, mode: LaunchMode.externalApplication);
    }

    if (!mounted) return;
    setState(() => _sosActive = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(
          l10n.safety_emergencyAlertSent,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── TRIP SHARING ────────────────────────────────────────────────────────────

  Future<void> _shareTrip() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSharingTrip = true);

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }

    if (!mounted) {
      setState(() => _isSharingTrip = false);
      return;
    }

    String shareText;
    if (position != null) {
      final mapsLink =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      shareText = l10n.safety_shareTripBody(mapsLink);
      if (_activeRideDestination != null) {
        shareText += '\n${l10n.safety_destinationLabelPrefix(_activeRideDestination!)}';
      }
    } else {
      shareText = l10n.safety_shareTripNoLocation;
    }

    await SharePlus.instance.share(ShareParams(text: shareText));

    if (!mounted) return;
    setState(() => _isSharingTrip = false);
  }

  Future<void> _startSafeRideTracking() async {
    final l10n = AppLocalizations.of(context)!;
    if (_activeRideId == null) return;
    setState(() => _isCreatingSafeRide = true);
    try {
      final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Utilizator';
      final url = await SafeRideService().createTrackingLink(
        rideId: _activeRideId!,
        passengerName: userName,
        destinationAddress: _activeRideDestination ?? '',
      );
      if (!mounted) return;
      setState(() => _safeRideTrackingUrl = url);
      await SafeRideService().shareLink(url, userName);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.safety_couldNotCreateTrackingLink)),
      );
    } finally {
      if (mounted) setState(() => _isCreatingSafeRide = false);
    }
  }

  // ── CONTACTS ────────────────────────────────────────────────────────────────

  Future<void> _addContact() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.addTrustedContact),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                hintText: l10n.phoneNumberExample,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty ||
                  phoneCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true) {
      final contact = TrustedContact(
        name: nameCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
      );
      await SafetyPreferences.addTrustedContact(contact);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactSaved(contact.name))),
      );
      await _loadContacts();
    }
  }

  Future<void> _removeContact(TrustedContact contact) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.safety_deleteContactTitle),
        content: Text(l10n.safety_deleteContactConfirmation(contact.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await SafetyPreferences.removeTrustedContact(contact);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.contactRemoved(contact.name))),
    );
    await _loadContacts();
  }

  Future<void> _sendTestMessage(TrustedContact contact) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri(
      scheme: 'sms',
      path: contact.phoneNumber,
      queryParameters: <String, String>{'body': l10n.testMessageBody},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotOpenMessages),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.safetyCenter),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l10n.addContact,
            onPressed: _addContact,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SOS BUTTON ──────────────────────────────────────────────
          _buildSOSCard(isDark),
          const SizedBox(height: 16),

          // ── SHARE TRIP ──────────────────────────────────────────────
          _buildShareTripCard(isDark),
          const SizedBox(height: 16),

          // ── INFO CARDS ──────────────────────────────────────────────
          _buildInfoCard(
            icon: Icons.report_problem_outlined,
            title: l10n.reportIncidentTitle,
            description: l10n.reportIncidentDesc,
            color: Colors.orange.shade600,
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/report'),
          ),
          const SizedBox(height: 24),

          // ── TRUSTED CONTACTS ────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.people_outline,
                  color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.trustedContacts,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactsList(l10n, isDark),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSOSCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emergency, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(
            l10n.safety_emergencyButtonTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.safety_emergencyButtonSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _sosPulse,
            child: GestureDetector(
              onTap: _sosActive ? null : _triggerSOS,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: _sosActive
                    ? const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sos,
                              color: Colors.red, size: 48),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareTripCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.share_location,
                      color: Colors.blue.shade700, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.safety_shareTripTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activeRideId != null
                            ? l10n.safety_activeRideDetected
                            : l10n.safety_sendCurrentLocation,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_activeRideDestination != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.safety_destinationLabelPrefix(_activeRideDestination!),
                        style: TextStyle(
                            color: Colors.blue.shade800, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSharingTrip ? null : _shareTrip,
                icon: _isSharingTrip
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(_isSharingTrip
                    ? l10n.safety_gettingLocation
                    : l10n.safety_shareLocationButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_activeRideId != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCreatingSafeRide ? null : _startSafeRideTracking,
                  icon: _isCreatingSafeRide
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gps_fixed),
                  label: Text(_safeRideTrackingUrl != null
                      ? l10n.safety_liveLinkActive
                      : l10n.safety_safeRideSharePath),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: onTap != null
            ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
            : null,
      ),
    );
  }

  Widget _buildContactsList(AppLocalizations l10n, bool isDark) {
    if (_isLoadingContacts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.group_add_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                l10n.safety_noContactsAdded,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.safety_addContactsDescription,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addContact,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(l10n.addContact),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _contacts.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (_, index) {
          final contact = _contacts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                contact.name.isNotEmpty
                    ? contact.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue.shade700),
              ),
            ),
            title: Text(contact.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(contact.phoneNumber),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: l10n.sendTestMessage,
                  icon: const Icon(Icons.sms_outlined),
                  onPressed: () => _sendTestMessage(contact),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeContact(contact),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
