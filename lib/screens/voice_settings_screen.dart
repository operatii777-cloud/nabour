import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../voice/passenger/passenger_voice_controller_adapter.dart';
import '../l10n/app_localizations.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  // ✅ NOU: Variabilele redundante eliminate - sistemul vocal este mereu activ
  // bool _isVoiceEnabled = true; // ❌ ELIMINAT
  // bool _isAutoListenEnabled = false; // ❌ ELIMINAT
  double _speechRate = 0.8;
  double _volume = 0.9;
  double _pitch = 1.0;
  String _selectedLanguage = 'ro-RO';
  // bool _isWakeWordEnabled = false; // ❌ ELIMINAT
  // bool _isContinuousListening = false; // ❌ ELIMINAT
  // String _wakeWord = 'Hey Nabour'; // ❌ ELIMINAT

  @override
  void initState() {
    super.initState();
    _loadVoiceSettings();
  }

  Future<void> _loadVoiceSettings() async {
    // Load saved settings from SharedPreferences or other storage
    // For now, using default values
  }

  Future<void> _saveVoiceSettings(BuildContext context) async {
    // Save settings to storage
    // Update voice orchestrator with new settings
    // final voiceController = context.read<PassengerVoiceController>();
    // Metoda updateSettings nu este implementată încă
    // await voiceController.voice.updateSettings(
    //   speechRate: _speechRate,
    //   volume: _volume,
    //   language: _selectedLanguage,
    //   pitch: _pitch,
    // );
    
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.voiceSettingsSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('🎤 ${l10n.voiceSettings}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showAdvancedHelp(),
            tooltip: l10n.advancedHelp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVoiceStatusCard(),
            const SizedBox(height: 24),
            _buildGeneralSettings(),
            const SizedBox(height: 24),
            _buildVoicePreferences(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceStatusCard() {
    return Consumer<PassengerVoiceControllerAdapter>(
      builder: (context, voiceController, child) {
        final l10n = AppLocalizations.of(context)!;
        final isInitialized = voiceController.isInitialized;
        
        return Card(
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isInitialized 
                  ? [Colors.green.shade100, Colors.green.shade50]
                  : [Colors.red.shade100, Colors.red.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isInitialized ? Icons.check_circle : Icons.error,
                      color: isInitialized ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isInitialized ? l10n.voiceSystemActive : l10n.voiceSystemNotActive,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isInitialized ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isInitialized 
                              ? l10n.canUseVoiceCommands
                              : l10n.checkMicrophonePermissions,
                            style: TextStyle(
                              color: isInitialized ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (isInitialized) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Voice Features Status
                  Row(
                    children: [
                      _buildFeatureStatus(
                        l10n.basicMode,
                        true, // Always enabled since detectarea "salut" is removed
                        Icons.hearing,
                      ),
                      const SizedBox(width: 16),
                      _buildFeatureStatus(
                        l10n.continuous,
                        voiceController.isContinuousListening,
                        Icons.mic,
                      ),
                      const SizedBox(width: 16),
                      _buildFeatureStatus(
                        l10n.privacy,
                        true,
                        Icons.security,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureStatus(String label, bool isEnabled, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? Colors.green.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? Colors.green : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isEnabled ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  isEnabled ? l10n.on : l10n.off,
                  style: TextStyle(
                    fontSize: 10,
                    color: isEnabled ? Colors.green.shade600 : Colors.grey.shade500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.generalSettings,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // ✅ NOU: Opțiunile redundante eliminate - sistemul vocal este mereu activ
                // SwitchListTile(...) // ❌ ELIMINAT - Activează controlul vocal
                // SwitchListTile(...) // ❌ ELIMINAT - Ascultare automată
                // SwitchListTile(...) // ❌ ELIMINAT - Cuvânt de activare

                SwitchListTile(
                  title: Text(l10n.continuousListening),
                  subtitle: Text(l10n.continuousListeningSubtitle),
                  value: context.watch<PassengerVoiceControllerAdapter>().isContinuousListening,
                  onChanged: (value) {
                    context.read<PassengerVoiceControllerAdapter>().toggleContinuousListening();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoicePreferences() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.voicePreferences,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(l10n.speechRate),
                Slider(
                  value: _speechRate,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  label: _speechRate.toStringAsFixed(1),
                  onChanged: (value) {
                    _safeSetState(() {
                      _speechRate = value;
                    });
                  },
                ),
                Text(
                  l10n.percentOfNormalSpeed((_speechRate * 100).round()),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                const SizedBox(height: 20),
                
                Text(l10n.volume),
                Slider(
                  value: _volume,
                  min: 0.1,
                  divisions: 9,
                  label: _volume.toStringAsFixed(1),
                  onChanged: (value) {
                    _safeSetState(() {
                      _volume = value;
                    });
                  },
                ),
                Text(
                  l10n.percentOfMaxVolume((_volume * 100).round()),
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 20),
                
                Text(l10n.pitch),
                Slider(
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _pitch.toStringAsFixed(1),
                  onChanged: (value) {
                    _safeSetState(() {
                      _pitch = value;
                    });
                  },
                ),
                Text(
                  _pitch < 1.0 ? l10n.lowerPitch : _pitch > 1.0 ? l10n.higherPitch : l10n.normalPitch,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                const SizedBox(height: 20),
                
                Text(l10n.language),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    DropdownMenuItem(value: 'ro-RO', child: Text(l10n.romanian)),
                    DropdownMenuItem(value: 'en-US', child: Text(l10n.english)),
                  ],
                  onChanged: (value) {
                    _safeSetState(() {
                      _selectedLanguage = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  
  Widget _buildSaveButton() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _saveVoiceSettings(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.saveSettings,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }


  void _showAdvancedHelp() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔧 ${l10n.advancedHelpTitle}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.advancedFeaturesAvailable, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(l10n.automaticVoiceActivation),
              Text(l10n.customActivationWord),
              Text(l10n.realtimeDetection),
              const SizedBox(height: 8),
              Text('🔄 ${l10n.continuousListening}'),
              Text(l10n.continuousListeningForCommands),
              Text(l10n.realtimeProcessing),
              Text(l10n.smartBatterySaving),
              const SizedBox(height: 8),
              Text('🌍 ${l10n.multiLanguageSupport}'),
              const Text('Suport complet pentru 2 limbi (RO/EN)'),
              Text(l10n.voiceSwitchBetweenLanguages),
              Text(l10n.localAccentAdaptation),
              const SizedBox(height: 8),
              Text('🔒 ${l10n.privacySecurity}'),
              Text(l10n.localProcessing),
              Text(l10n.endToEndEncryption),
              Text(l10n.fullDataControl),
              const SizedBox(height: 16),
              Text(
                l10n.contactSupportForTechnical,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
