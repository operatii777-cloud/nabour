import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nabour_app/utils/logger.dart';

class MicrophoneTest extends StatefulWidget {
  const MicrophoneTest({super.key});

  @override
  State<MicrophoneTest> createState() => _MicrophoneTestState();
}

class _MicrophoneTestState extends State<MicrophoneTest> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastWords = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      // Check current permission status
      var micPermission = await Permission.microphone.status;
      Logger.debug('Current permission status: $micPermission');
      
      // Request microphone permission if not granted
      if (!micPermission.isGranted) {
        micPermission = await Permission.microphone.request();
        Logger.debug('Permission after request: $micPermission');
      }
      
      // Handle different permission states
      if (micPermission.isDenied) {
        setState(() {
          _status = '❌ Microphone permission denied. Please enable in Settings → Apps → Nabour → Permissions → Microphone';
        });
        return;
      }
      
      if (micPermission.isPermanentlyDenied) {
        setState(() {
          _status = '❌ Microphone permanently denied. Go to Settings → Apps → Nabour → Permissions → Microphone → Allow';
        });
        return;
      }
      
      if (!micPermission.isGranted) {
        setState(() {
          _status = '❌ Microphone permission not granted: $micPermission';
        });
        return;
      }

      // Initialize Speech-to-Text with detailed debugging
      Logger.debug('Attempting to initialize Speech-to-Text...');
      final available = await _speechToText.initialize(
        onError: (error) {
          Logger.error('Speech error: ${error.errorMsg}, permanent: ${error.permanent}');
          setState(() {
            _status = '❌ Speech error: ${error.errorMsg}\nPermanent: ${error.permanent}';
          });
        },
        onStatus: (status) {
          Logger.debug('Speech status: $status');
          setState(() {
            _status = '🎤 Status: $status';
          });
        },
        debugLogging: true,
      );

      Logger.debug('Speech-to-Text available: $available');
      
      // More detailed status
      if (available) {
        final locales = await _speechToText.locales();
        Logger.debug('Available locales: ${locales.length}');
        for (var locale in locales) {
          Logger.debug('Locale: ${locale.localeId} - ${locale.name}');
        }
        
        setState(() {
          _isInitialized = true;
          _status = '✅ Speech-to-Text initialized\nLocales available: ${locales.length}';
        });
      } else {
        setState(() {
          _isInitialized = false;
          _status = '❌ Speech-to-Text not available\nPossible causes:\n- Speech recognition not supported\n- Google Play Services missing\n- No internet connection';
        });
      }
    } catch (e) {
      Logger.error('Speech initialization error: $e', error: e);
      setState(() {
        _status = '❌ Error: $e';
      });
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      setState(() {
        _status = '❌ Speech-to-Text not initialized';
      });
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _status = '🎤 Listening...';
      });

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
            if (result.finalResult) {
              _isListening = false;
              _status = '✅ Final result: ${result.recognizedWords}';
            }
          });
          Logger.debug('Result: ${result.recognizedWords}');
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          
        ),
        localeId: 'ro_RO',
      );
    } catch (e) {
      Logger.error('Listen error: $e', error: e);
      setState(() {
        _status = '❌ Listen error: $e';
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _status = '🛑 Stopped listening';
      });
    } catch (e) {
      Logger.error('Stop error: $e', error: e);
    }
  }

  Future<void> _checkSystemRequirements() async {
    String requirements = '🔍 System Check:\n\n';
    
    try {
      // Check if speech recognition is available
      final available = await _speechToText.hasPermission;
      requirements += '✅ Permissions: $available\n';
      
      // Check Speech-to-Text initialization without errors
      final speechAvailable = await SpeechToText().initialize();
      requirements += speechAvailable ? '✅ Speech Service: Available\n' : '❌ Speech Service: Not Available\n';
      
      // Check microphone permission specifically
      final micPermission = await Permission.microphone.status;
      requirements += '✅ Microphone Permission: $micPermission\n';
      
      requirements += '\n📋 Requirements for Speech-to-Text:\n';
      requirements += '• Android 5.0+ (API 21+)\n';
      requirements += '• Google Play Services\n';
      requirements += '• Internet connection\n';
      requirements += '• Working microphone\n';
      requirements += '• Google app installed\n';
      
      requirements += '\n💡 Solutions if not working:\n';
      requirements += '• Update Google Play Services\n';
      requirements += '• Update Google app\n';
      requirements += '• Check internet connection\n';
      requirements += '• Restart device\n';
      requirements += '• Clear app cache\n';
      
    } catch (e) {
      requirements += '❌ Error checking requirements: $e\n';
    }
    
    setState(() {
      _status = requirements;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Microphone Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _status.contains('❌') ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isListening ? null : _startListening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isListening ? 'Listening...' : '🎤 Start Listening',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isListening ? _stopListening : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('🛑 Stop'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Help Buttons
            if (!_isInitialized)
              Column(
                children: [
                  if (_status.contains('permission'))
                    ElevatedButton.icon(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Open App Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _initSpeech,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Initialization'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _checkSystemRequirements,
                    icon: const Icon(Icons.info),
                    label: const Text('Check System Requirements'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Results Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastWords.isEmpty ? 'No words detected yet' : _lastWords,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Debug Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Debug Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Initialized: $_isInitialized'),
                    Text('Listening: $_isListening'),
                    Text('Permission: ${Permission.microphone.status}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }
}
