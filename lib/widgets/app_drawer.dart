import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/screens/about_screen.dart';
import 'package:nabour_app/screens/auth_screen.dart';
import 'package:nabour_app/screens/driver_application_screen.dart';
import 'package:nabour_app/screens/help_screen.dart';
import 'package:nabour_app/screens/legal_screen.dart';
import 'package:nabour_app/screens/safety_screen.dart';
import 'package:nabour_app/screens/join_team_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/screens/driver_dashboard_screen.dart';
import 'package:nabour_app/screens/personal_info_screen.dart';
import 'package:nabour_app/theme/app_text_styles.dart';

// --- MODIFICAT: Am adăugat importurile necesare ---
import 'package:nabour_app/screens/history_screen.dart';
import 'package:nabour_app/screens/ride_broadcast_screen.dart';
import 'package:nabour_app/screens/neighborhood_chat_screen.dart';
import 'package:nabour_app/widgets/token_wallet_widget.dart';
import 'package:nabour_app/screens/voice_settings_screen.dart';
import 'package:nabour_app/screens/business_offers_screen.dart';
import 'package:nabour_app/screens/business_intro_screen.dart';
import 'package:nabour_app/screens/business_dashboard_screen.dart';
import 'package:nabour_app/services/business_service.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/screens/settings_screen.dart';
import 'package:nabour_app/services/trial_config_service.dart';
import 'package:nabour_app/screens/week_review_screen.dart';
import 'package:nabour_app/services/movement_history_service.dart';
import 'package:nabour_app/screens/favorite_addresses_screen.dart';
import 'package:nabour_app/screens/places_hub_screen.dart';
import 'package:nabour_app/screens/explorari_screen.dart';
import 'package:nabour_app/screens/mystery_box_activity_screen.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_model.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_shop_sheet.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/theme/theme_provider.dart';

const int _kTrialDays = 7;

class AppDrawer extends StatelessWidget {
  final UserRole currentRole;
  final Function(bool) onRoleChanged;
  final bool isVisibleToNeighbors;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onManageExclusions;
  final VoidCallback? onRefreshContacts; // ✅ NOU: Callback pentru refresh contacte
  static bool lowDataMode = false;
  static bool showPerfOverlay = false;

  const AppDrawer({
    super.key,
    required this.currentRole,
    required this.onRoleChanged,
    this.isVisibleToNeighbors = false,
    this.onToggleVisibility,
    this.onManageExclusions,
    this.onRefreshContacts,
    this.onAvatarChanged,
    this.onPlaceMapOrientationPin,
    this.onRemoveMapOrientationPin,
    this.onEnableSavedHomePinOnMap,
  });

  /// Long-press pe hartă plasează reperul (vezi ecranul hartă).
  final VoidCallback? onPlaceMapOrientationPin;
  final VoidCallback? onRemoveMapOrientationPin;
  /// Pin „Acasă” din favorite, vizibil doar pe clientul userului.
  final VoidCallback? onEnableSavedHomePinOnMap;

  /// După cumpărare sau Aplică în garaj; la închidere fără acțiune — fără argumente.
  final void Function([
    CarAvatar? selected,
    CarAvatarMapSlot? editedSlot,
    Map<CarAvatarMapSlot, String>? appliedIdsBySlot,
  ])? onAvatarChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final FirestoreService firestoreService = FirestoreService();

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: firestoreService.getUserProfileStream(),
              builder: (context, snapshot) {
                String displayName = l10n.drawerDefaultUserName;
                final String email = FirebaseAuth.instance.currentUser?.email ?? '';
                String phoneNumber = '';
                ImageProvider? profileImage;

                if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
                  final data = snapshot.data?.data();
                  if (data != null) {
                    displayName = data['displayName'] ?? displayName;
                    phoneNumber = data['phoneNumber'] ?? '';
                    final photoURL = data['photoURL'] as String?;
                    if (photoURL != null && photoURL.isNotEmpty) {
                      profileImage = NetworkImage(photoURL);
                    }
                  }
                }

                return Container(
                  height: 140, // Înălțime redusă pentru a evita overflow-ul
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F5FF1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 25, // Redus și mai mult
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        backgroundImage: profileImage,
                        child: profileImage == null
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: TextStyle(fontSize: 24.0, color: Theme.of(context).primaryColor),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Informații utilizator
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.menuHeader.copyWith(
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: AppTextStyles.menuSubtitle.copyWith(
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (phoneNumber.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                phoneNumber,
                                style: AppTextStyles.menuSubtitle.copyWith(
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Sold tokeni ──────────────────────────────────────────────
            const TokenWalletWidget.drawer(),

            // ── Informații Trial/Abonament (future memorat; key=uid evită cache greșit la schimb cont) ──
            _TrialBannerWidget(
              key: ValueKey(FirebaseAuth.instance.currentUser?.uid ?? ''),
            ),

            // ── Switch Șofer / Pasager ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentRole != UserRole.passenger) {
                            onRoleChanged(false);
                            Navigator.of(context).pop();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: currentRole == UserRole.passenger
                                ? const Color(0xFF7C3AED)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: currentRole == UserRole.passenger
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.drawerRolePassenger,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: currentRole == UserRole.passenger
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentRole != UserRole.driver) {
                            onRoleChanged(true);
                            Navigator.of(context).pop();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: currentRole == UserRole.driver
                                ? const Color(0xFF00E676)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.drive_eta_rounded,
                                size: 18,
                                color: currentRole == UserRole.driver
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.drawerRoleDriver,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: currentRole == UserRole.driver
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tema Dark / Light ───────────────────────────────────────
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                final isDark = themeProvider.isDarkMode;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            size: 20,
                            color: isDark ? Colors.amber.shade300 : Colors.orange.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isDark ? l10n.drawerThemeDarkLabel : l10n.drawerThemeLightLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                RotationTransition(turns: animation, child: child),
                            child: Icon(
                              isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                              key: ValueKey(isDark),
                              size: 20,
                              color: isDark ? Colors.blue.shade200 : Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

              // ==========================================
              // 1. ACTIVITATE ȘI CONT
              // ==========================================
              _buildSectionHeader(l10n.drawerSectionActivityAccount),
              _buildMenuItem(context,
                icon: Icons.account_circle_rounded,
                color: Colors.blue.shade600,
                title: l10n.profile,
                onTap: () => _navigateTo(context, const PersonalInfoScreen()),
              ),
              _buildMenuItem(context,
                icon: Icons.history_rounded,
                color: const Color(0xFF00C6FF),
                title: l10n.rideHistory,
                onTap: () => _navigateTo(context, const HistoryScreen()),
              ),
              _buildMenuItem(
                context,
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFFF007F),
                title: l10n.drawerMenuWeekReview,
                onTap: () => _navigateTo(context, const WeekReviewScreen()),
              ),
              _buildMenuItem(
                context,
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF0D9488),
                title: l10n.drawerMenuMysteryBoxActivity,
                onTap: () => _navigateTo(context, const MysteryBoxActivityScreen()),
              ),
              _buildMenuItem(
                context,
                icon: Icons.auto_awesome_motion_rounded,
                color: const Color(0xFFFFD700), // Gold/Amber premium
                title: 'GALAXY GARAGE',
                onTap: () {
                  Navigator.pop(context); // Închide drawer-ul
                  CarAvatarShopSheet.show(context, onClosed: onAvatarChanged);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.home_filled,
                color: const Color(0xFF22C55E),
                title: 'Afișează Acasă (favorite) pe hartă\n(doar pentru tine)',
                onTap: () {
                  Navigator.pop(context);
                  onEnableSavedHomePinOnMap?.call();
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.home_work_rounded,
                color: const Color(0xFF38BDF8),
                title: 'Reper orientare pe hartă\n(ține apăsat pe hartă după activare)',
                onTap: () {
                  Navigator.pop(context);
                  onPlaceMapOrientationPin?.call();
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.pin_drop_outlined,
                color: Colors.orange.shade700,
                title: 'Ascunde Acasă / elimină reper manual',
                onTap: () {
                  Navigator.pop(context);
                  onRemoveMapOrientationPin?.call();
                },
              ),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.bookmark_added_rounded,
                        color: Colors.teal.shade700, size: 22),
                  ),
                  title: Text(
                    l10n.drawerSectionAddresses,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.star_rounded,
                      color: Colors.amber.shade700,
                      title: l10n.drawerFavoriteAddresses,
                      onTap: () => _navigateTo(context, const FavoriteAddressesScreen()),
                      isSubItem: true,
                    ),
                  ],
                ),
              ),
              if (currentRole == UserRole.driver)
                _buildMenuItem(context,
                  icon: Icons.dashboard_rounded,
                  color: const Color(0xFF00E676), // A bright vibrant green
                  title: l10n.driverDashboard,
                  onTap: () => _navigateTo(context, const DriverDashboardScreen()),
                ),

              // ==========================================
              // 2. COMUNITATEA NABOUR
              // ==========================================
              const SizedBox(height: 8),
              _buildSectionHeader(l10n.drawerSectionYourCommunity),
              _buildMenuItem(context,
                icon: Icons.campaign_rounded,
                color: const Color(0xFF7C3AED),
                title: l10n.neighborhoodRequests,
                onTap: () => _navigateTo(context, const RideBroadcastFeedScreen()),
              ),
              _buildMenuItem(context,
                icon: Icons.forum_rounded,
                color: const Color(0xFF7C3AED),
                title: l10n.neighborhoodChat,
                onTap: () => _navigateTo(context, const NeighborhoodChatScreen()),
              ),
              _buildMenuItem(context,
                icon: Icons.map_rounded,
                color: const Color(0xFF00B894),
                title: l10n.drawerMenuPlaces,
                onTap: () => _navigateTo(context, const PlacesHubScreen()),
              ),
              _buildMenuItem(context,
                icon: Icons.grid_goldenratio_rounded,
                color: const Color(0xFFFF6B9D),
                title: l10n.drawerMenuExplorations,
                onTap: () => _navigateTo(context, const ExplorariScreen()),
              ),
              _buildMenuItem(context,
                icon: Icons.storefront_rounded,
                color: const Color(0xFFFF6B35),
                title: l10n.drawerBusinessOffersTitle,
                onTap: () => _navigateTo(context, const BusinessOffersScreen()),
              ),
              _buildMenuItem(context,
                leadingWidget: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isVisibleToNeighbors ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    key: ValueKey(isVisibleToNeighbors),
                    color: isVisibleToNeighbors ? const Color(0xFF7C3AED) : Colors.grey.shade500,
                    size: 22,
                  ),
                ),
                color: isVisibleToNeighbors ? const Color(0xFF7C3AED) : Colors.grey.shade500,
                title: l10n.drawerSocialMapTitle,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVisibleToNeighbors ? const Color(0xFF7C3AED).withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isVisibleToNeighbors ? l10n.drawerSocialVisible : l10n.drawerSocialHidden,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isVisibleToNeighbors ? const Color(0xFF7C3AED) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                onTap: onToggleVisibility ?? () {},
              ),

              // ✅ NOU: Buton de sincronizare contacte (ajută când nu apar vecinii)
              _buildMenuItem(context,
                icon: Icons.sync_rounded,
                color: Colors.blueGrey,
                title: l10n.drawerMenuSyncContacts,
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  onPressed: () => _showSyncInfo(context),
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () {
                  Navigator.pop(context); // Închide drawer-ul
                  onRefreshContacts?.call();
                },
              ),

              _buildMenuItem(context,
                icon: Icons.settings_rounded,
                color: Colors.blueGrey,
                title: l10n.settings,
                onTap: () => _navigateTo(context, SettingsScreen(
                  onManageExclusions: onManageExclusions,
                )),
              ),

              // ==========================================
              // 3. AFACEREA MEA
              // ==========================================
              const SizedBox(height: 8),
              _buildSectionHeader(l10n.drawerSectionMyBusiness),
              _DrawerBusinessProfileSlot(
                navigateTo: _navigateTo,
                buildMenuItem: _buildMenuItem,
              ),

              // ==========================================
              // 4. IMPLICARE (pasageri)
              // ==========================================
              if (currentRole == UserRole.passenger) ...[
                const SizedBox(height: 8),
                _buildSectionHeader(l10n.drawerSectionGetInvolved),
                _buildMenuItem(context,
                  icon: Icons.group_add_rounded,
                  color: const Color(0xFFF9A826), // Vibrant Orange/Yellow
                  title: l10n.joinTeam,
                  onTap: () => _navigateTo(context, const JoinTeamScreen()),
                ),
                _buildMenuItem(context,
                  icon: Icons.drive_eta_rounded,
                  color: const Color(0xFF00E676),
                  title: l10n.applyForDriver,
                  onTap: () => _navigateTo(context, const DriverApplicationScreen()),
                ),
              ],

              // ==========================================
              // 5. PREFERINȚE ȘI AI
              // ==========================================
              const SizedBox(height: 8),
              _buildSectionHeader(l10n.drawerSectionAiPerformance),
              
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                  ),
                  title: Text(l10n.aiAssistant, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                  children: [
                     _buildMenuItem(context,
                      icon: Icons.mic_rounded,
                      color: Colors.blue,
                      title: l10n.drawerVoiceAiSettingsTitle,
                      onTap: () => _navigateTo(context, const VoiceSettingsScreen()),
                      isSubItem: true,
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 5. SUPORT ȘI LEGAL
              // ==========================================
              const SizedBox(height: 8),
              _buildSectionHeader(l10n.drawerSectionSupportInfo),
              _buildMenuItem(context,
                icon: Icons.security_rounded,
                color: Colors.amber.shade600,
                title: l10n.safety,
                onTap: () => _navigateTo(context, const SafetyScreen()),
              ),
              _buildMenuItem(context,
                icon: Icons.help_outline_rounded,
                color: Colors.grey.shade500,
                title: l10n.help,
                onTap: () => _navigateToWithRole(context, HelpScreen(isPassengerMode: currentRole == UserRole.passenger)),
              ),
              _buildMenuItem(context,
                icon: Icons.people_alt_rounded,
                color: Colors.grey.shade500,
                title: l10n.drawerTeamNabour,
                onTap: () => _navigateToWithRole(context, AboutScreen(isPassengerMode: currentRole == UserRole.passenger)),
              ),
              _buildMenuItem(context,
                icon: Icons.gavel_rounded,
                color: Colors.grey.shade500,
                title: l10n.legal,
                onTap: () => _navigateTo(context, const LegalScreen()),
              ),

              // ==========================================
              // 6. LOGOUT
              // ==========================================
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Material(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: Colors.red.withValues(alpha: 0.2),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await MovementHistoryService.instance.stopRecorder();
                      await FirebaseAuth.instance.signOut();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            l10n.logout,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.red.shade600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade400,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    IconData? icon,
    Widget? leadingWidget,
    required Color color,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    bool isSubItem = false,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: isSubItem ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isSubItem ? 10 : 12,
              horizontal: 12,
            ),
            child: Row(
              children: [
                if (isSubItem) const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.all(isSubItem ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isSubItem ? 10 : 14),
                  ),
                  child: leadingWidget ?? Icon(icon, color: color, size: isSubItem ? 18 : 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSubItem ? 13 : 15,
                      fontWeight: isSubItem ? FontWeight.w600 : FontWeight.w700,
                      color: onSurface.withValues(alpha: isSubItem ? 0.75 : 1.0),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
                if (trailing != null) trailing
                else Icon(Icons.chevron_right_rounded, color: onSurface.withValues(alpha: 0.3), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    if (!Navigator.of(context).mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => screen));
  }

  void _navigateToWithRole(BuildContext context, Widget screen) {
    if (!Navigator.of(context).mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => screen));
  }

  void _showSyncInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.drawerSyncContactsDialogTitle),
        content: Text(l10n.drawerSyncContactsDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.drawerSyncContactsDialogOk),
          ),
        ],
      ),
    );
  }
}

/// Profil business încărcat o dată pe ciclu de viață drawer, nu la fiecare rebuild MapScreen.
class _DrawerBusinessProfileSlot extends StatefulWidget {
  const _DrawerBusinessProfileSlot({
    required this.navigateTo,
    required this.buildMenuItem,
  });

  final void Function(BuildContext context, Widget screen) navigateTo;
  final Widget Function(
    BuildContext context, {
    IconData? icon,
    Widget? leadingWidget,
    required Color color,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    bool isSubItem,
  }) buildMenuItem;

  @override
  State<_DrawerBusinessProfileSlot> createState() =>
      _DrawerBusinessProfileSlotState();
}

class _DrawerBusinessProfileSlotState extends State<_DrawerBusinessProfileSlot> {
  late final Future<BusinessProfile?> _profileFuture =
      BusinessService().getMyProfile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<BusinessProfile?>(
      future: _profileFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final profile = snap.data;
        if (profile != null) {
          return widget.buildMenuItem(
            context,
            icon: Icons.dashboard_customize_rounded,
            color: const Color(0xFFFF6B35),
            title: l10n.drawerBusinessDashboardTitle(profile.businessName),
            onTap: () => widget.navigateTo(
              context,
              BusinessDashboardScreen(profileId: profile.id),
            ),
          );
        }
        return widget.buildMenuItem(
          context,
          icon: Icons.store_mall_directory_rounded,
          color: const Color(0xFFFF6B35),
          title: l10n.drawerBusinessRegisterTitle,
          onTap: () => widget.navigateTo(context, const BusinessIntroScreen()),
        );
      },
    );
  }
}

// ── Trial banner afișat în drawer ─────────────────────────────────────────────
class _TrialBannerWidget extends StatefulWidget {
  const _TrialBannerWidget({super.key});

  @override
  State<_TrialBannerWidget> createState() => _TrialBannerWidgetState();
}

class _TrialBannerWidgetState extends State<_TrialBannerWidget> {
  late final Future<bool> _exemptFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _exemptFuture = TrialConfigService.instance
        .isExempt(uid: user?.uid, email: user?.email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final creationTime = user?.metadata.creationTime;

    return FutureBuilder<bool>(
      future: _exemptFuture,
      builder: (context, snap) {
        final isExempt = snap.data == true;

        String title;
        String subtitle;
        Color accentColor;

        if (isExempt) {
          title = l10n.drawerTrialPrivilegedTitle;
          subtitle = l10n.drawerTrialPrivilegedSubtitle;
          accentColor = const Color(0xFF00C853);
        } else if (creationTime == null) {
          title = l10n.drawerTrialSevenDayTitle;
          subtitle = l10n.drawerTrialPricingSubtitle;
          accentColor = const Color(0xFF5A32FA);
        } else {
          final trialEnd = creationTime.add(const Duration(days: _kTrialDays));
          final daysLeft = trialEnd.difference(DateTime.now()).inDays;
          if (daysLeft > 0) {
            title = l10n.drawerTrialDaysLeftTitle(daysLeft);
            subtitle = l10n.drawerTrialDuringSubtitle;
            accentColor = daysLeft <= 2
                ? const Color(0xFFFF6D00)
                : const Color(0xFF5A32FA);
          } else {
            title = l10n.drawerTrialExpiredTitle;
            subtitle = l10n.drawerTrialExpiredSubtitle;
            accentColor = const Color(0xFFD32F2F);
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExempt
                        ? Icons.verified_rounded
                        : Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

