import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/screens/auth_screen.dart';
import 'package:nabour_app/screens/personal_info_screen.dart';
import 'package:nabour_app/screens/saved_addresses_screen.dart';
import 'package:nabour_app/screens/security_screen.dart';
import 'package:nabour_app/screens/history_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/widgets/drv_verify_badge_widget.dart';
import 'package:nabour_app/models/driver_verification_model.dart';
import 'package:nabour_app/screens/ride_preferences_screen.dart';
import 'package:nabour_app/screens/business_profile_screen.dart';
import 'package:nabour_app/screens/selfie_verification_screen.dart';
import 'package:nabour_app/screens/notif_prefs_screen.dart';
import 'package:nabour_app/screens/privacy_settings_screen.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/widgets/token_wallet_widget.dart';
import 'package:nabour_app/l10n/app_localizations.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Obține verificările șoferului din Firestore
  Future<List<DriverVerification>> _getDriverVerifications() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final snap = await FirebaseFirestore.instance
          .collection('driver_verifications')
          .where('driverId', isEqualTo: uid)
          .get();

      return snap.docs
          .map((doc) => DriverVerification.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      Logger.error('Error getting driver verifications: $e', error: e);
      return [];
    }
  }

  Widget _buildMenuOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.accountScreenTitle),
          ),
          body: StreamBuilder(
            stream: _firestoreService.getUserProfileStream(),
            builder: (context, profileSnapshot) {
              if (!profileSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final userData = profileSnapshot.data?.data();
              final bool isDriver = userData?['role'] == 'driver';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F5FF1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          _ProfileAvatar(
                            avatar: userData?['avatar'] as String? ?? '🙂',
                            displayName: user?.displayName ??
                                userData?['displayName'] as String? ??
                                l10n.accountDefaultNeighbor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.email ?? 'email@exemplu.com',
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          if (isDriver) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.accountDriverPartnerBadge,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            // ✅ NOU: Badge-uri de verificare
                            const SizedBox(height: 8),
                            FutureBuilder<List<DriverVerification>>(
                              future: _getDriverVerifications(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                  final badges = snapshot.data!
                                      .map((v) => DriverVerificationBadge.fromVerification(v))
                                      .toList();
                                  return DriverVerificationBadgesList(
                                    badges: badges,
                                    compact: true,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Sold tokeni ──────────────────────────────────────
                    const TokenWalletWidget.profile(),

                    _buildMenuOption(
                      icon: Icons.person_outline,
                      title: isDriver
                          ? l10n.accountMenuDriverVehicleDetails
                          : l10n.accountMenuPersonalDetails,
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PersonalInfoScreen()));
                      },
                    ),
                    
                    _buildMenuOption(
                      icon: Icons.security_outlined,
                      title: l10n.accountMenuSecurity,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SecurityScreen()));
                      },
                    ),
                    
                     _buildMenuOption(
                      icon: Icons.home_work_outlined,
                      title: l10n.accountMenuSavedAddresses,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SavedAddressesScreen()));
                      },
                    ),
                    
                    // ✅ NOU: Preferințe cursă
                    _buildMenuOption(
                      icon: Icons.settings,
                      title: l10n.accountMenuRidePreferences,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const RidePreferencesScreen()));
                      },
                    ),
                    
                    _buildMenuOption(
                      icon: Icons.history_outlined,
                      title: l10n.accountMenuRideHistory,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const HistoryScreen()));
                      },
                    ),

                    // Feature: Business profile — for corporate accounts and expense receipts
                    _buildMenuOption(
                      icon: Icons.business_center_outlined,
                      title: l10n.accountMenuBusinessProfile,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BusinessProfileScreen()));
                      },
                    ),

                    // Feature: Selfie identity verification
                    _buildMenuOption(
                      icon: Icons.face_retouching_natural,
                      title: l10n.accountMenuSelfieVerification,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SelfieVerificationScreen()));
                      },
                    ),

                    _buildMenuOption(
                      icon: Icons.notifications_outlined,
                      title: l10n.accountMenuNotifications,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const NotificationPreferencesScreen()));
                      },
                    ),

                    _buildMenuOption(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.accountMenuPrivacy,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PrivacySettingsScreen()));
                      },
                    ),
                    
                    const Divider(),
                    
                     _buildMenuOption(
                      icon: Icons.delete_forever_outlined,
                      title: l10n.accountDeleteTitle,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.accountDeleteTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.accountDeleteBody),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.accountDeletePasswordLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.accountDeletePasswordError;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // --- MODIFICARE: Salvăm referințele la Navigator și ScaffoldMessenger înainte de 'await' ---
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Închide dialogul curent de parolă
                Navigator.of(dialogContext).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(child: CircularProgressIndicator()),
                );

                final result = await _firestoreService.deleteUserAccount(
                  password: passwordController.text,
                );

                // --- MODIFICARE: Verificăm 'mounted' înainte de a folosi contextul salvat ---
                if (!mounted) return;

                // Închide dialogul de încărcare folosind referința salvată
                navigator.pop(); 

                if (result['success']) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.green,
                    ),
                  );
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                    (route) => false,
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.accountDeleteConfirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Avatar de profil cu nametag Nabour ────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final String avatar;
  final String displayName;

  const _ProfileAvatar({required this.avatar, required this.displayName});

  String get _firstName => displayName.split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.60), width: 3),
          ),
          child: Center(
            child: Text(avatar, style: const TextStyle(fontSize: 42)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _firstName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}