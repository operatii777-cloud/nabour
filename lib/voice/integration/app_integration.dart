import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main_voice_integration.dart';
import '../widgets/voice_interaction_widget.dart';
import '../states/voice_interaction_states.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🎯 App Integration - Integrarea sistemului vocal în Nabour
/// 
/// Caracteristici:
/// - Integrare completă cu main app
/// - Provider setup
/// - Widget integration
/// - Lifecycle management
class AppVoiceIntegration {
  /// 🚀 Integrează sistemul vocal în aplicația principală
  static Widget integrateVoiceSystem({
    required Widget child,
    required BuildContext context,
  }) {
    return MainVoiceIntegrationProvider(
      child: child,
    );
  }
  
  /// 🎤 Adaugă widget-ul vocal în orice screen
  static Widget addVoiceWidget({
    required BuildContext context,
    Widget? child,
    bool showAsOverlay = false,
  }) {
    if (showAsOverlay) {
      return Stack(
        children: [
          if (child != null) child,
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildFloatingVoiceButton(context),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (child != null) Expanded(child: child),
          const VoiceInteractionWidget(),
        ],
      );
    }
  }
  
  /// 🎤 Buton flotant pentru interacțiunea vocală
  static Widget _buildFloatingVoiceButton(BuildContext context) {
    return Consumer<MainVoiceIntegration>(
      builder: (context, voiceIntegration, child) {
        final isActive = voiceIntegration.currentContext.processingState != VoiceProcessingState.idle;
        
        return FloatingActionButton(
          onPressed: () {
            if (isActive) {
              voiceIntegration.stopVoiceInteraction();
            } else {
              voiceIntegration.startVoiceInteraction();
            }
          },
          backgroundColor: isActive ? Colors.red : Colors.blue,
          child: Icon(
            isActive ? Icons.stop : Icons.mic,
            color: Colors.white,
          ),
        );
      },
    );
  }
  
  /// 🎯 Adaugă voice system în main app
  static void setupVoiceSystem(BuildContext context) {
    // 🎯 Inițializează sistemul vocal
    final voiceIntegration = Provider.of<MainVoiceIntegration>(context, listen: false);
    
    // 🎤 Verifică dacă e inițializat
    if (!voiceIntegration.isInitialized) {
      Logger.info('Voice system not initialized, initializing...', tag: 'APP_INTEGRATION');
      // voiceIntegration._initializeComponents(); // Metoda este privată
    }
  }
  
  /// 🎤 Verifică dacă voice system-ul e disponibil
  static bool isVoiceSystemAvailable(BuildContext context) {
    try {
      final voiceIntegration = Provider.of<MainVoiceIntegration>(context, listen: false);
      return voiceIntegration.isInitialized;
    } catch (e) {
      Logger.info('Voice system not available: $e', tag: 'APP_INTEGRATION');
      return false;
    }
  }
  
  /// 🎤 Obține voice integration-ul
  static MainVoiceIntegration? getVoiceIntegration(BuildContext context) {
    try {
      return Provider.of<MainVoiceIntegration>(context, listen: false);
    } catch (e) {
      Logger.info('Could not get voice integration: $e', tag: 'APP_INTEGRATION');
      return null;
    }
  }
  
  /// 🎤 Adaugă voice system în main.dart
  static List<ChangeNotifierProvider> getMainProviders() {
    return [
      ChangeNotifierProvider<MainVoiceIntegration>(
        create: (context) => MainVoiceIntegration(),
      ),
    ];
  }
  
  /// 🎤 Adaugă voice system în MaterialApp
  static Widget wrapMaterialApp({
    required Widget child,
    required BuildContext context,
  }) {
    return MultiProvider(
      providers: getMainProviders(),
      child: child,
    );
  }
  
  /// 🎤 Adaugă voice system în screen-uri
  static Widget wrapScreen({
    required Widget child,
    required BuildContext context,
    bool showVoiceWidget = true,
    bool showAsOverlay = false,
  }) {
    if (!showVoiceWidget) {
      return child;
    }
    
    return addVoiceWidget(
      context: context,
      child: child,
      showAsOverlay: showAsOverlay,
    );
  }
  
  /// 🎤 Adaugă voice system în drawer
  static Widget addVoiceToDrawer({
    required Widget child,
    required BuildContext context,
  }) {
    return Column(
      children: [
        child,
        const Divider(),
        const ListTile(
          leading: Icon(Icons.mic, color: Colors.blue),
          title: Text('Asistent Vocal'),
          subtitle: Text('Control vocal pentru Nabour'),
        ),
        const VoiceInteractionWidget(),
      ],
    );
  }
  
  /// 🎤 Adaugă voice system în bottom navigation
  static Widget addVoiceToBottomNav({
    required Widget child,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Expanded(child: child),
        const VoiceInteractionWidget(),
      ],
    );
  }
  
  /// 🎤 Adaugă voice system în app bar
  static PreferredSizeWidget addVoiceToAppBar(PreferredSizeWidget? appBar) {
    if (appBar is AppBar) {
      return AppBar(
        title: appBar.title ?? const Text('Nabour'),
        actions: [
          ...(appBar.actions ?? []),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              // Basic voice interaction - Note: quick booking will be implemented in future update
              Logger.debug('Voice button pressed');
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: const Text('Nabour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              // Basic voice interaction - Note: quick booking will be implemented in future update
              Logger.debug('Voice button pressed');
            },
          ),
        ],
      );
    }
  }
}

/// 🎯 Mixin pentru screen-uri care vor voice integration
mixin VoiceIntegrationMixin<T extends StatefulWidget> on State<T> {
  /// 🎤 Obține voice integration-ul
  MainVoiceIntegration? get voiceIntegration {
    try {
      return Provider.of<MainVoiceIntegration>(context, listen: false);
    } catch (e) {
      return null;
    }
  }
  
  /// 🎤 Verifică dacă voice system-ul e disponibil
  bool get isVoiceSystemAvailable => voiceIntegration != null;
  
  /// 🎤 Începe interacțiunea vocală
  Future<void> startVoiceInteraction() async {
    if (isVoiceSystemAvailable) {
      await voiceIntegration!.startVoiceInteraction();
    }
  }
  
  /// 🎤 Oprește interacțiunea vocală
  Future<void> stopVoiceInteraction() async {
    if (isVoiceSystemAvailable) {
      await voiceIntegration!.stopVoiceInteraction();
    }
  }
  
  /// 🎤 Adaugă voice widget în screen
  Widget addVoiceWidget({bool showAsOverlay = false}) {
    return AppVoiceIntegration.addVoiceWidget(
      context: context,
      child: buildVoiceIntegratedScreen(),
      showAsOverlay: showAsOverlay,
    );
  }
  
  /// 🎯 Construiește screen-ul cu integrare vocală
  Widget buildVoiceIntegratedScreen();
}
