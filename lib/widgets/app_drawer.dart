import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:nabour_app/screens/token_transfer_screen.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_model.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_shop_sheet.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/theme/theme_provider.dart';
import 'package:nabour_app/core/ui/app_feedback.dart';
import 'package:nabour_app/services/app_sound_service.dart';
import 'package:nabour_app/services/assistant_voice_ui_prefs.dart';

const int _kTrialDays = 7;

/// După [Navigator.pop] pe drawer, contextul item-ului poate fi scos din arbore
/// (crash: `_elements.contains(element)`). Folosim navigatorul root în frame-ul următor.
void _popDrawerThen(BuildContext drawerContext, void Function(BuildContext safeContext) action) {
  final nav = Navigator.of(drawerContext, rootNavigator: true);
  Navigator.pop(drawerContext);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!nav.mounted) return;
    action(nav.context);
  });
}

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
    this.onHideSavedHomePinOnMap,
    this.onRemoveOrientationReperFromMap,
    this.onEnableSavedHomePinOnMap,
  });

  /// Long-press pe hartă plasează reperul (vezi ecranul hartă).
  final VoidCallback? onPlaceMapOrientationPin;
  /// Ascunde doar markerul Acasă (favorite), fără a atinge reperul de orientare.
  final VoidCallback? onHideSavedHomePinOnMap;
  /// Elimină doar reperul manual (ac compas), fără a atinge Acasă.
  final VoidCallback? onRemoveOrientationReperFromMap;
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
            _DrawerProfileHeader(
              key: ValueKey('drawer_profile_${FirebaseAuth.instance.currentUser?.uid ?? ''}'),
              firestoreService: firestoreService,
              defaultUserName: l10n.drawerDefaultUserName,
            ),

            // ── Sold tokeni ──────────────────────────────────────────────
            const TokenWalletWidget.drawer(),

            // ── Informații Trial/Abonament (future memorat; key=uid evită cache greșit la schimb cont) ──
            _TrialBannerWidget(
              key: ValueKey('drawer_trial_${FirebaseAuth.instance.currentUser?.uid ?? ''}'),
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
            _buildDrawerGroup(
              context,
              title: l10n.drawerGroupAccountActivity,
              icon: Icons.person_pin_circle_outlined,
              accentColor: Colors.blue.shade600,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.account_circle_rounded,
                  color: Colors.blue.shade600,
                  title: l10n.profile,
                  onTap: () => _navigateTo(context, const PersonalInfoScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history_rounded,
                  color: const Color(0xFF00C6FF),
                  title: l10n.rideHistory,
                  onTap: () => _navigateTo(context, const HistoryScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFFFF007F),
                  title: l10n.drawerMenuWeekReview,
                  onTap: () => _navigateTo(context, const WeekReviewScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF0D9488),
                  title: l10n.drawerMenuMysteryBoxActivity,
                  onTap: () => _navigateTo(context, const MysteryBoxActivityScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.swap_horiz_rounded,
                  color: const Color(0xFF0D9488),
                  title: l10n.drawerMenuTokenTransfer,
                  onTap: () => _navigateTo(context, const TokenTransferScreen()),
                  isSubItem: true,
                ),
                if (currentRole == UserRole.passenger)
                  _buildMenuItem(
                    context,
                    icon: Icons.drive_eta_rounded,
                    color: const Color(0xFF00E676),
                    title: l10n.applyForDriver,
                    onTap: () => _navigateTo(context, const DriverApplicationScreen()),
                    isSubItem: true,
                  ),
                _buildMenuItem(
                  context,
                  icon: Icons.auto_awesome_motion_rounded,
                  color: const Color(0xFFFFD700),
                  title: 'GALAXY GARAGE',
                  onTap: () => _popDrawerThen(context, (safe) {
                    CarAvatarShopSheet.show(safe, onClosed: onAvatarChanged);
                  }),
                  isSubItem: true,
                ),
                if (currentRole == UserRole.driver)
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    color: const Color(0xFF00E676),
                    title: l10n.driverDashboard,
                    onTap: () => _navigateTo(context, const DriverDashboardScreen()),
                    isSubItem: true,
                  ),
              ],
            ),
            _buildDrawerGroup(
              context,
              title: l10n.drawerGroupMapAddresses,
              icon: Icons.layers_outlined,
              accentColor: Colors.teal.shade700,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.star_rounded,
                  color: Colors.amber.shade700,
                  title: l10n.drawerFavoriteAddresses,
                  onTap: () => _navigateTo(context, const FavoriteAddressesScreen()),
                  isSubItem: true,
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
                  isSubItem: true,
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
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.visibility_off_outlined,
                  color: Colors.orange.shade700,
                  title: 'Ascunde Acasă de pe hartă\n(doar markerul favorite)',
                  onTap: () {
                    Navigator.pop(context);
                    onHideSavedHomePinOnMap?.call();
                  },
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.pin_drop_outlined,
                  color: const Color(0xFF15803D),
                  title: 'Ascunde reper orientare\n(elimină acul de pe hartă)',
                  onTap: () {
                    Navigator.pop(context);
                    onRemoveOrientationReperFromMap?.call();
                  },
                  isSubItem: true,
                ),
              ],
            ),

            // ==========================================
            // 2. COMUNITATEA NABOUR
            // ==========================================
            const SizedBox(height: 8),
            _buildSectionHeader(l10n.drawerSectionYourCommunity),
            _buildDrawerGroup(
              context,
              title: l10n.drawerGroupCommunityFeed,
              icon: Icons.groups_2_outlined,
              accentColor: const Color(0xFF7C3AED),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFF7C3AED),
                  title: l10n.neighborhoodRequests,
                  onTap: () => _navigateTo(context, const RideBroadcastFeedScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.forum_rounded,
                  color: const Color(0xFF7C3AED),
                  title: l10n.neighborhoodChat,
                  onTap: () => _navigateTo(context, const NeighborhoodChatScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.map_rounded,
                  color: const Color(0xFF00B894),
                  title: l10n.drawerMenuPlaces,
                  onTap: () => _navigateTo(context, const PlacesHubScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.grid_goldenratio_rounded,
                  color: const Color(0xFFFF6B9D),
                  title: l10n.drawerMenuExplorations,
                  onTap: () => _navigateTo(context, const ExplorariScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFFFF6B35),
                  title: l10n.drawerBusinessOffersTitle,
                  onTap: () => _navigateTo(context, const BusinessOffersScreen()),
                  isSubItem: true,
                ),
              ],
            ),
            _buildDrawerGroup(
              context,
              title: l10n.drawerGroupSocialApp,
              icon: Icons.tune_rounded,
              accentColor: Colors.blueGrey.shade600,
              children: [
                _buildMenuItem(
                  context,
                  leadingWidget: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
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
                      color: isVisibleToNeighbors
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isVisibleToNeighbors ? l10n.drawerSocialVisible : l10n.drawerSocialHidden,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isVisibleToNeighbors
                            ? const Color(0xFF7C3AED)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  onTap: onToggleVisibility ?? () {},
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.sync_rounded,
                  color: Colors.blueGrey,
                  title: l10n.drawerMenuSyncContacts,
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    onPressed: () => _showSyncInfo(context),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onRefreshContacts?.call();
                  },
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_rounded,
                  color: Colors.blueGrey,
                  title: l10n.settings,
                  onTap: () => _navigateTo(
                    context,
                    SettingsScreen(onManageExclusions: onManageExclusions),
                  ),
                  isSubItem: true,
                ),
              ],
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
              _buildDrawerGroup(
                context,
                title: l10n.drawerSectionGetInvolved,
                icon: Icons.front_hand_outlined,
                accentColor: const Color(0xFFF9A826),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.group_add_rounded,
                    color: const Color(0xFFF9A826),
                    title: l10n.joinTeam,
                    onTap: () => _navigateTo(context, const JoinTeamScreen()),
                    isSubItem: true,
                  ),
                ],
              ),
            ],

            // ==========================================
            // 5. PREFERINȚE ȘI ASISTENT VOCAL (opțional din setări)
            // ==========================================
            ValueListenableBuilder<bool>(
              valueListenable:
                  AssistantVoiceUiPrefs.instance.visibilityNotifier,
              builder: (context, showAssistant, _) {
                if (!showAssistant) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildSectionHeader(l10n.drawerSectionAiPerformance),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.psychology_rounded,
                              color: Colors.white, size: 22),
                        ),
                        iconColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        collapsedIconColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        title: Text(
                          l10n.aiAssistant,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.mic_rounded,
                            color: Colors.blue,
                            title: l10n.drawerVoiceAiSettingsTitle,
                            onTap: () => _navigateTo(
                                context, const VoiceSettingsScreen()),
                            isSubItem: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // ==========================================
            // 6. SUPORT ȘI LEGAL
            // ==========================================
            const SizedBox(height: 8),
            _buildSectionHeader(l10n.drawerSectionSupportInfo),
            _buildDrawerGroup(
              context,
              title: l10n.drawerGroupHelpLegal,
              icon: Icons.support_agent_rounded,
              accentColor: Colors.grey.shade600,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.security_rounded,
                  color: Colors.amber.shade600,
                  title: l10n.safety,
                  onTap: () => _navigateTo(context, const SafetyScreen()),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  color: Colors.grey.shade500,
                  title: l10n.help,
                  onTap: () => _navigateToWithRole(
                    context,
                    HelpScreen(isPassengerMode: currentRole == UserRole.passenger),
                  ),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_alt_rounded,
                  color: Colors.grey.shade500,
                  title: l10n.drawerTeamNabour,
                  onTap: () => _navigateToWithRole(
                    context,
                    AboutScreen(isPassengerMode: currentRole == UserRole.passenger),
                  ),
                  isSubItem: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.gavel_rounded,
                  color: Colors.grey.shade500,
                  title: l10n.legal,
                  onTap: () => _navigateTo(context, const LegalScreen()),
                  isSubItem: true,
                ),
              ],
            ),

            // ==========================================
            // 7. LOGOUT
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

  /// Grup compact (ExpansionTile) pentru subcategorii în drawer.
  Widget _buildDrawerGroup(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        iconColor: scheme.onSurface.withValues(alpha: 0.45),
        collapsedIconColor: scheme.onSurface.withValues(alpha: 0.45),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: scheme.onSurface,
          ),
        ),
        children: children,
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
    final nav = Navigator.of(context, rootNavigator: true);
    if (!nav.mounted) return;
    AppSoundService.instance.playMenuClick();

    Navigator.pop(context);

    // Tranziție zoom + fade la navigarea din drawer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!nav.mounted) return;
      nav.push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            );
            final fade = CurvedAnimation(parent: animation, curve: Curves.easeIn);

            return ScaleTransition(
              scale: scale,
              child: FadeTransition(
                opacity: fade,
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  void _navigateToWithRole(BuildContext context, Widget screen) {
    _navigateTo(context, screen);
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

/// Antet drawer cu poză și date cont: fără reconstruiri la fiecare emisie Firestore
/// și fără reîncărcare repetată a imaginii de profil (cauză frecventă de flickering).
class _DrawerProfileHeader extends StatefulWidget {
  const _DrawerProfileHeader({
    super.key,
    required this.firestoreService,
    required this.defaultUserName,
  });

  final FirestoreService firestoreService;
  final String defaultUserName;

  @override
  State<_DrawerProfileHeader> createState() => _DrawerProfileHeaderState();
}

class _DrawerProfileHeaderState extends State<_DrawerProfileHeader> {
  late String _displayName;
  late String _email;
  String _phone = '';
  String? _photoUrl;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _email = user?.email ?? '';
    _displayName = widget.defaultUserName;
    if (user != null) {
      final dn = user.displayName?.trim();
      if (dn != null && dn.isNotEmpty) {
        _displayName = dn;
      }
      final p = user.photoURL?.trim();
      if (p != null && p.isNotEmpty) {
        _photoUrl = p;
      }
    }

    final stream = widget.firestoreService.getUserProfileStream();
    _sub = stream.listen(_onProfileSnapshot, onError: (_) {});
  }

  void _onProfileSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!mounted) return;
    final data = snap.data();
    if (data == null) return;

    final rawName = data['displayName'];
    final displayName = (rawName != null && rawName.toString().trim().isNotEmpty)
        ? rawName.toString().trim()
        : widget.defaultUserName;

    final rawPhone = data['phoneNumber'];
    final phone = rawPhone == null ? '' : rawPhone.toString().trim();

    String? photoUrl;
    final rawPhoto = data['photoURL'];
    if (rawPhoto is String && rawPhoto.trim().isNotEmpty) {
      photoUrl = rawPhoto.trim();
    } else {
      final authUrl = FirebaseAuth.instance.currentUser?.photoURL?.trim();
      if (authUrl != null && authUrl.isNotEmpty) {
        photoUrl = authUrl;
      }
    }

    if (displayName == _displayName &&
        phone == _phone &&
        photoUrl == _photoUrl) {
      return;
    }
    setState(() {
      _displayName = displayName;
      _phone = phone;
      _photoUrl = photoUrl;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String get _initialLetter {
    if (_displayName.isEmpty) return 'U';
    return _displayName.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return RepaintBoundary(
      child: Container(
        height: 140,
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
            CircleAvatar(
              radius: 25,
              backgroundColor: theme.scaffoldBackgroundColor,
              child: _photoUrl != null && _photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _photoUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: (50 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                        memCacheHeight: (50 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                        placeholder: (_, __) => ColoredBox(
                          color: theme.scaffoldBackgroundColor,
                          child: Center(
                            child: Text(
                              _initialLetter,
                              style: TextStyle(
                                fontSize: 24,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Text(
                          _initialLetter,
                          style: TextStyle(
                            fontSize: 24,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      _initialLetter,
                      style: TextStyle(
                        fontSize: 24,
                        color: theme.primaryColor,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _displayName,
                    style: AppTextStyles.menuHeader.copyWith(
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: AppTextStyles.menuSubtitle.copyWith(
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (_phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _phone,
                      style: AppTextStyles.menuSubtitle.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      if (uid != null) {
                        Clipboard.setData(ClipboardData(text: uid));
                        AppFeedback.success(context, 'ID copiat în clipboard.');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge, size: 10, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${uid != null && uid.length >= 8 ? uid.substring(0, 8) : '...'}(...)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy, size: 10, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

