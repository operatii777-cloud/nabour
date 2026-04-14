import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/theme/theme_provider.dart';
import 'package:nabour_app/providers/locale_provider.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/widgets/update_banner_widget.dart';
import 'package:nabour_app/widgets/app_drawer.dart'; // Pentru lowDataMode static
import 'package:nabour_app/services/community_mode_service.dart';
import 'package:nabour_app/services/mhist_prefs_service.dart';
import 'package:nabour_app/services/movement_history_service.dart';
import 'package:nabour_app/services/nearby_social_notif_prefs.dart';
import 'package:nabour_app/services/assistant_voice_ui_prefs.dart';
import 'package:nabour_app/services/now_playing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nabour_app/core/ui/app_feedback.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onManageExclusions;

  const SettingsScreen({
    super.key,
    this.onManageExclusions,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _movementHistoryEnabled = false;
  bool _movementHistoryLoaded = false;
  int _movementRetentionDays = 90;
  bool _nearbyNotifyEnabled = true;
  int _nearbyRadiusM = 500;
  bool _nearbyPrefsLoaded = false;
  String _npTitle = '';
  String _npArtist = '';
  bool _fuzzyLocationEnabled = false;
  bool _assistantVoiceUiVisible = false;
  bool _assistantVoiceUiLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMovementHistoryPref();
    _loadNearbySocialPrefs();
    _loadSocialProfileFields();
    _loadFuzzyLocationPref();
    _loadAssistantVoiceUiPref();
  }

  Future<void> _loadAssistantVoiceUiPref() async {
    await AssistantVoiceUiPrefs.instance.load();
    if (!mounted) return;
    setState(() {
      _assistantVoiceUiVisible =
          AssistantVoiceUiPrefs.instance.visibilityNotifier.value;
      _assistantVoiceUiLoaded = true;
    });
  }

  Future<void> _loadFuzzyLocationPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fuzzyLocationEnabled = prefs.getBool('fuzzy_location') ?? false;
    });
  }

  Future<void> _loadSocialProfileFields() async {
    await CommunityModeService.instance.load();
    final u = FirebaseAuth.instance.currentUser?.uid;
    if (u != null) {
      try {
        final d =
            await FirebaseFirestore.instance.collection('users').doc(u).get();
        final np = d.data()?['nowPlaying'] as Map<String, dynamic>?;
        if (!mounted) return;
        setState(() {
          _npTitle = np?['title'] as String? ?? '';
          _npArtist = np?['artist'] as String? ?? '';
        });
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  String _communitySubtitle() {
    final l10n = AppLocalizations.of(context)!;
    final m = CommunityModeService.instance.mode;
    if (m == 'school') {
      final s = CommunityModeService.instance.schoolLabel;
      return s.isEmpty ? l10n.settingsCommunityModeSchool : s;
    }
    return l10n.settingsCommunityModeStandard;
  }

  String _nowPlayingSubtitle() {
    final l10n = AppLocalizations.of(context)!;
    if (_npTitle.isEmpty && _npArtist.isEmpty) {
      return l10n.settingsNowPlayingNotSet;
    }
    return '$_npTitle · $_npArtist'.trim();
  }

  Future<void> _loadNearbySocialPrefs() async {
    await NearbySocialNotificationsPrefs.instance.load();
    if (!mounted) return;
    setState(() {
      _nearbyNotifyEnabled = NearbySocialNotificationsPrefs.instance.enabled;
      _nearbyRadiusM = NearbySocialNotificationsPrefs.instance.radiusM;
      _nearbyPrefsLoaded = true;
    });
  }

  Future<void> _loadMovementHistoryPref() async {
    final enabled = await MovementHistoryPreferencesService.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      _movementHistoryEnabled = enabled;
      _movementHistoryLoaded = true;
    });
    await _loadMovementRetention();
  }

  Future<void> _loadMovementRetention() async {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getInt('movement_history_retention_days') ?? 90;
    if (!mounted) return;
    setState(() => _movementRetentionDays = days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── SECȚIUNE: ACTUALIZĂRI ──────────────────────────────────────────
          _buildSectionHeader(context, l10n.settingsSectionUpdates),
          const AppVersionTile(),
          const Divider(height: 1),

          // ── SECȚIUNE: PREFERINȚE INTERFAȚĂ ─────────────────────────────────
          _buildSectionHeader(context, l10n.settingsSectionInterfaceData),
          
          // Contrast ridicat
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => _buildSwitchTile(
              context,
              icon: Icons.contrast_rounded,
              color: Colors.blue.shade700,
              title: l10n.highContrastUI,
              value: themeProvider.isHighContrast,
              onChanged: (val) => themeProvider.toggleHighContrast(),
            ),
          ),

          // Mod date reduse
          StatefulBuilder(
            builder: (context, setState) => _buildSwitchTile(
              context,
              icon: Icons.data_saver_on_rounded,
              color: Colors.teal.shade700,
              title: l10n.lowDataMode,
              value: AppDrawer.lowDataMode,
              onChanged: (val) {
                setState(() => AppDrawer.lowDataMode = val);
              },
            ),
          ),
          _buildSwitchTile(
            context,
            icon: Icons.graphic_eq_rounded,
            color: const Color(0xFF6366F1),
            title: l10n.settingsVoiceAssistantOnMap,
            subtitle: l10n.settingsVoiceAssistantOnMapSubtitle,
            value: _assistantVoiceUiLoaded ? _assistantVoiceUiVisible : false,
            onChanged: !_assistantVoiceUiLoaded
                ? (_) {}
                : (val) async {
                    setState(() => _assistantVoiceUiVisible = val);
                    await AssistantVoiceUiPrefs.instance.setVisible(val);
                  },
          ),

          const Divider(height: 1),

          // ── SECȚIUNE: PRIVACY & LIMBĂ ─────────────────────────────────────
          _buildSectionHeader(context, l10n.settingsSectionPrivacyLanguage),

          // Exclude vizibilitatea
          if (widget.onManageExclusions != null)
            ListTile(
              leading: _buildIconContainer(Icons.person_off_rounded, Colors.grey.shade700),
              title: Text(l10n.settingsVisibilityExclusionsTitle),
              subtitle: Text(
                l10n.settingsVisibilityExclusionsSubtitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: widget.onManageExclusions,
            ),
          ListTile(
            leading: _buildIconContainer(Icons.visibility_off_rounded, Colors.deepPurple),
            title: Text(l10n.settingsGhostModeTitle),
            subtitle: Text(
              l10n.settingsGhostModeSubtitle,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildSwitchTile(
            context,
            icon: Icons.blur_circular_rounded,
            color: const Color(0xFF6366F1),
            title: l10n.settingsApproximateLocationTitle,
            value: _fuzzyLocationEnabled,
            onChanged: (val) async {
              setState(() => _fuzzyLocationEnabled = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('fuzzy_location', val);
            },
          ),
          _buildSectionHeader(context, l10n.settingsSocialMapSection),
          _buildSwitchTile(
            context,
            icon: Icons.place_rounded,
            color: const Color(0xFF7C3AED),
            title: l10n.settingsNearbyNotificationsTitle,
            value: _nearbyPrefsLoaded ? _nearbyNotifyEnabled : true,
            onChanged: !_nearbyPrefsLoaded
                ? (_) {}
                : (val) async {
                    setState(() => _nearbyNotifyEnabled = val);
                    await NearbySocialNotificationsPrefs.instance.setEnabled(val);
                  },
          ),
          ListTile(
            leading: _buildIconContainer(Icons.straighten_rounded, Colors.indigo.shade700),
            title: Text(l10n.settingsNearbyAlertRadiusTitle),
            subtitle: Text(l10n.settingsNearbyAlertRadiusSubtitle(_nearbyRadiusM)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: !_nearbyPrefsLoaded ? null : () => _pickNearbyRadius(context),
          ),
          ListTile(
            leading: _buildIconContainer(Icons.music_note_rounded, Colors.green.shade700),
            title: Text(l10n.settingsMusicTitle),
            subtitle: Text(l10n.settingsMusicSubtitle),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () async {
              final u = Uri.parse('https://open.spotify.com');
              if (await canLaunchUrl(u)) {
                await launchUrl(u, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListTile(
            leading: _buildIconContainer(Icons.graphic_eq_rounded, Colors.purple.shade600),
            title: Text(l10n.settingsNowPlayingTitle),
            subtitle: Text(_nowPlayingSubtitle()),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openNowPlayingSheet(context),
          ),
          ListTile(
            leading: _buildIconContainer(Icons.groups_rounded, Colors.deepOrange.shade600),
            title: Text(l10n.settingsCommunityModeTitle),
            subtitle: Text(_communitySubtitle()),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openCommunitySheet(context),
          ),
          _buildSwitchTile(
            context,
            icon: Icons.timeline_rounded,
            color: const Color(0xFF7C3AED),
            title: l10n.settingsLocationHistoryTitle,
            value: _movementHistoryEnabled,
            onChanged: _movementHistoryLoaded
                ? (val) async {
                    setState(() => _movementHistoryEnabled = val);
                    await MovementHistoryPreferencesService.instance.setEnabled(val);
                    if (val) {
                      final ok = await MovementHistoryService.instance.startRecorder();
                      if (!context.mounted) return;
                      if (!ok) {
                        await MovementHistoryPreferencesService.instance.setEnabled(false);
                        if (!context.mounted) return;
                        setState(() => _movementHistoryEnabled = false);
                        AppFeedback.error(
                          context,
                          l10n.settingsLocationHistoryStartFailed,
                        );
                        return;
                      }
                    } else {
                      await MovementHistoryService.instance.stopRecorder();
                    }
                    if (!context.mounted) return;
                    if (val) {
                      AppFeedback.success(
                        context,
                        l10n.settingsLocationHistoryEnabled,
                      );
                    } else {
                      AppFeedback.info(context, l10n.settingsLocationHistoryDisabled);
                    }
                  }
                : (_) {},
          ),
          ListTile(
            leading: _buildIconContainer(Icons.auto_delete_rounded, Colors.deepPurple),
            title: Text(
              l10n.settingsLocalHistoryRetentionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 14 : null),
            ),
            subtitle: Text(
              l10n.settingsLocalHistoryRetentionSubtitle(_movementRetentionDays),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _pickRetentionDays,
          ),
          ListTile(
            leading: _buildIconContainer(Icons.delete_forever_rounded, Colors.red.shade600),
            title: Text(
              l10n.settingsDeleteLocalHistoryTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.settingsDeleteLocalHistorySubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: _confirmAndClearLocalHistory,
          ),

          // Limba
          _buildLanguageTile(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _pickNearbyRadius(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final choices = [200, 400, 500, 800, 1200, 2000];
    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                l10n.settingsNearbyNotificationRadiusTitle,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            for (final m in choices)
              ListTile(
                title: Text('$m m'),
                trailing: _nearbyRadiusM == m ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      await NearbySocialNotificationsPrefs.instance.setRadiusM(picked);
      setState(() => _nearbyRadiusM = picked);
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: _buildIconContainer(icon, color),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
      minVerticalPadding: 8,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
        activeTrackColor: color.withAlpha(100),
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final isRo = provider.locale.languageCode == 'ro';

    return ListTile(
      leading: _buildIconContainer(Icons.language_rounded, Colors.indigo),
      title: Text(
        l10n.language,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: SizedBox(
        width: 118,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                isRo ? l10n.romanian : l10n.english,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
      onTap: () => _showLanguagePicker(context, provider, l10n),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider provider, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.language, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🇷🇴', style: TextStyle(fontSize: 24)),
              title: Text(l10n.romanian),
              trailing: provider.locale.languageCode == 'ro' ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () {
                provider.setLocale(const Locale('ro'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(l10n.english),
              trailing: provider.locale.languageCode == 'en' ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () {
                provider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRetentionDays() async {
    final l10n = AppLocalizations.of(context)!;
    final options = <int>[30, 60, 90, 180, 365];
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.settingsLocalHistoryRetentionTitle,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...options.map((d) => ListTile(
                  title: Text('$d zile'),
                  trailing: _movementRetentionDays == d
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => Navigator.of(context).pop(d),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('movement_history_retention_days', selected);
    await MovementHistoryService.instance.pruneLocalRetention(retentionDays: selected);
    if (!mounted) return;
    setState(() => _movementRetentionDays = selected);
    AppFeedback.success(context, l10n.settingsLocalHistoryRetentionSet(selected));
  }

  Future<void> _openNowPlayingSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final tCtrl = TextEditingController(text: _npTitle);
    final aCtrl = TextEditingController(text: _npArtist);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settingsNowPlayingSheetTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tCtrl,
              decoration: InputDecoration(labelText: l10n.settingsNowPlayingSongLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: aCtrl,
              decoration: const InputDecoration(labelText: 'Artist'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await NowPlayingService.instance.publish(
                  title: tCtrl.text,
                  artist: aCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                setState(() {
                  _npTitle = tCtrl.text.trim();
                  _npArtist = aCtrl.text.trim();
                });
                AppFeedback.success(this.context, l10n.settingsMusicProfileUpdated);
              },
              child: Text(l10n.settingsSaveToAccount),
            ),
            TextButton(
              onPressed: () async {
                await NowPlayingService.instance.clear();
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                setState(() {
                  _npTitle = '';
                  _npArtist = '';
                });
              },
              child: Text(l10n.settingsDeleteFromProfile),
            ),
          ],
        ),
      ),
    );
    tCtrl.dispose();
    aCtrl.dispose();
  }

  Future<void> _openCommunitySheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    String sheetMode =
        CommunityModeService.instance.mode == 'school' ? 'school' : 'none';
    final schoolCtrl =
        TextEditingController(text: CommunityModeService.instance.schoolLabel);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsCommunitySheetTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Mod'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: sheetMode,
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Standard')),
                      DropdownMenuItem(
                        value: 'school',
                        child: Text('Școală / liceu / facultate'),
                      ),
                    ],
                    onChanged: (v) => setModal(() => sheetMode = v ?? 'none'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: schoolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nume instituție (opțional)',
                  hintText: 'Ex: Liceul X',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await CommunityModeService.instance.setModeAndSchool(
                    mode: sheetMode == 'school' ? 'school' : 'none',
                    schoolLabel: schoolCtrl.text,
                  );
                  if (context.mounted) Navigator.pop(ctx);
                  if (mounted) setState(() {});
                  if (context.mounted) {
                    AppFeedback.success(context, l10n.settingsCommunityModeSaved);
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
    schoolCtrl.dispose();
  }

  Future<void> _confirmAndClearLocalHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDeleteLocalHistoryConfirmTitle),
        content: Text(
          l10n.settingsDeleteLocalHistoryConfirmContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await MovementHistoryService.instance.clearLocalHistoryForCurrentUser();
    if (!mounted) return;
    AppFeedback.success(context, l10n.settingsLocalHistoryDeleted);
  }
}
