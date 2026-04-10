import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/services/app_audio_session.dart';

class WalkieTalkieService {
  static final WalkieTalkieService _instance = WalkieTalkieService._internal();
  factory WalkieTalkieService() => _instance;
  WalkieTalkieService._internal();

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  /// În așteptare până pornește efectiv înregistrarea (evită stop înainte de start).
  Future<void>? _startFuture;

  String? _lastRecordPath;

  /// Așteaptă finalul încercării de start (pentru stop corect la eliberarea degetului).
  Future<void> waitForStartSettled() async {
    final f = _startFuture;
    if (f != null) await f;
  }

  /// Pornește înregistrarea; returnează false dacă permisiunea e refuzată sau start-ul eșuează.
  Future<bool> startRecording() async {
    _startFuture = _startRecordingImpl();
    await _startFuture;
    _startFuture = null;
    return _isRecording;
  }

  Future<void> _startRecordingImpl() async {
    try {
      var mic = await Permission.microphone.status;
      if (!mic.isGranted) {
        mic = await Permission.microphone.request();
      }
      if (!mic.isGranted) {
        Logger.warning('WalkieTalkie: microphone permission denied');
        return;
      }
      if (!await _audioRecorder.hasPermission()) {
        Logger.warning('WalkieTalkie: record plugin reported no permission');
        return;
      }
      await AppAudioSession.ensureConfiguredForVoiceCommunication();
      final directory = await getTemporaryDirectory();
      _lastRecordPath =
          '${directory.path}/walkie_talkie_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        kVoiceRecordingRecordConfig,
        path: _lastRecordPath!,
      );
      _isRecording = true;
      Logger.info('WalkieTalkie: Started recording at $_lastRecordPath');
    } catch (e) {
      Logger.error('WalkieTalkie: Start recording error: $e', error: e);
      _isRecording = false;
    }
  }

  /// Oprește fără upload (anulare sau durată prea scurtă).
  Future<void> discardRecording() async {
    await waitForStartSettled();
    try {
      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        if (path != null) {
          final file = File(path);
          if (file.existsSync()) await file.delete();
        }
      } else {
        _isRecording = false;
      }
    } catch (e) {
      Logger.warning('WalkieTalkie: discardRecording: $e');
      _isRecording = false;
    }
  }

  Future<String?> stopRecordingAndUpload(String roomId) async {
    await waitForStartSettled();
    try {
      if (!_isRecording && !await _audioRecorder.isRecording()) {
        return null;
      }

      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path == null) return null;

      final file = File(path);
      if (!file.existsSync()) return null;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('walkie_talkie')
          .child(roomId)
          .child('${DateTime.now().millisecondsSinceEpoch}.m4a');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      try {
        if (file.existsSync()) await file.delete();
      } catch (_) {}

      Logger.info('WalkieTalkie: Uploaded audio: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('WalkieTalkie: Stop and upload error: $e', error: e);
      _isRecording = false;
      return null;
    }
  }

  Future<void> playAudio(String url) async {
    try {
      Logger.info('WalkieTalkie: Auto-playing audio: $url');
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      Logger.error('WalkieTalkie: Play error: $e', error: e);
    }
  }

  Future<void> playAsset(String path) async {
    try {
      Logger.info('WalkieTalkie: Playing asset sound: $path');
      await _audioPlayer.play(AssetSource(path));
    } catch (e) {
      Logger.error('WalkieTalkie: Play asset error: $e', error: e);
    }
  }

  StreamSubscription? _roomSubscription;
  String? _currentRoomId;

  /// Ascultă mesaje vocale noi dintr-o cameră H3 și le redă automat
  void listenToRoom(String roomId) {
    if (_currentRoomId == roomId && _roomSubscription != null) return;
    
    _roomSubscription?.cancel();
    _currentRoomId = roomId;
    
    _roomSubscription = FirebaseFirestore.instance
        .collection('neighborhood_chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) return;
      
      final data = snap.docs.first.data();
      final senderUid = data['uid'] as String?;
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final type = data['type'] as String?;
      final voiceUrl = data['voiceUrl'] as String?;
      final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

      if (type == 'voice' && voiceUrl != null && senderUid != myUid && 
          timestamp != null && DateTime.now().difference(timestamp).inSeconds < 10) {
        playAudio(voiceUrl);
      }
    });
    
    Logger.info('WalkieTalkie: Listening for auto-play in room $roomId');
  }

  Future<void> stopListening() async {
    await _roomSubscription?.cancel();
    _roomSubscription = null;
    _currentRoomId = null;
  }

  /// Nu elibera [AudioRecorder]/[AudioPlayer]: serviciul e singleton; dispose-ul le-ar
  /// distruge și următoarea deschidere a chat-ului de cartier nu mai poate înregistra.
  void dispose() {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _currentRoomId = null;
  }
}
