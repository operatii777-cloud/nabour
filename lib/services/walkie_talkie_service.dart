import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:nabour_app/utils/logger.dart';

class WalkieTalkieService {
  static final WalkieTalkieService _instance = WalkieTalkieService._internal();
  factory WalkieTalkieService() => _instance;
  WalkieTalkieService._internal();

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String? _lastRecordPath;

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _lastRecordPath = '${directory.path}/walkie_talkie_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig(
          
        );

        await _audioRecorder.start(config, path: _lastRecordPath!);
        _isRecording = true;
        Logger.info('WalkieTalkie: Started recording at $_lastRecordPath');
      }
    } catch (e) {
      Logger.error('WalkieTalkie: Start recording error: $e', error: e);
    }
  }

  Future<String?> stopRecordingAndUpload(String roomId) async {
    try {
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
      
      Logger.info('WalkieTalkie: Uploaded audio: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('WalkieTalkie: Stop and upload error: $e', error: e);
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

  void dispose() {
    _roomSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
