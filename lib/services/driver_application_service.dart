import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nabour_app/models/driver_document_model.dart';
import 'package:nabour_app/utils/logger.dart';

class DriverApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Stream pentru aplicația curentă
  Stream<DriverApplicationData?> get applicationStream {
    if (_currentUserId == null) return Stream.value(null);
    
    return _firestore
        .collection('driver_applications')
        .doc(_currentUserId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return DriverApplicationData();
      return DriverApplicationData.fromFirestore(snapshot.data()!);
    });
  }

  // Salvează informațiile personale
  Future<void> savePersonalInfo({
    required String fullName,
    required String age,
  }) async {
    if (_currentUserId == null) throw Exception('Utilizator neautentificat');

    await _firestore
        .collection('driver_applications')
        .doc(_currentUserId)
        .set({
      'fullName': fullName,
      'age': age,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Logger.debug('Personal info saved for user: $_currentUserId');
  }

  // Salvează informațiile despre mașină
  Future<void> saveCarInfo({
    required String carBrand,
    required String carModel,
    required String carColor,
    required String carYear,
    required String licensePlate,
  }) async {
    if (_currentUserId == null) throw Exception('Utilizator neautentificat');

    await _firestore
        .collection('driver_applications')
        .doc(_currentUserId)
        .set({
      'carBrand': carBrand,
      'carModel': carModel,
      'carColor': carColor,
      'carYear': carYear,
      'licensePlate': licensePlate.toUpperCase(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Logger.debug('Car info saved for user: $_currentUserId');
  }

  // Salvează informațiile finale
  Future<void> saveFinalInfo({
    required String bankAccount,
  }) async {
    if (_currentUserId == null) throw Exception('Utilizator neautentificat');

    await _firestore
        .collection('driver_applications')
        .doc(_currentUserId)
        .set({
      'bankAccount': bankAccount,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Logger.debug('Final info saved for user: $_currentUserId');
  }

  // Încarcă document
  Future<String> uploadDocument({
    required DriverDocumentType documentType,
    required File file,
    required String fileName,
  }) async {
    if (_currentUserId == null) throw Exception('Utilizator neautentificat');

    try {
      Logger.debug('=== UPLOADING ${documentType.displayName} ===');
      
      // Verifică dimensiunea fișierului (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Fișierul este prea mare. Dimensiunea maximă permisă este 10MB.');
      }

      Logger.debug('File size: $fileSize bytes');

      // Creează referința Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final storageFileName = '${_currentUserId}_${documentType.name}_$timestamp.$extension';
      
      final storageRef = _storage
          .ref()
          .child('driver_applications')
          .child(documentType.storageFolder)
          .child(storageFileName);

      Logger.debug('Storage path: ${storageRef.fullPath}');

      // Determină content type
      String contentType = 'application/octet-stream';
      if (['jpg', 'jpeg'].contains(extension)) {
        contentType = 'image/jpeg';
      } else if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'pdf') {
        contentType = 'application/pdf';
      }

      // Metadata pentru upload
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'documentType': documentType.name,
          'uploadedBy': _currentUserId!,
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFileName': fileName,
        },
      );

      Logger.debug('Starting upload...');
      
      // Upload fișier
      final uploadTask = await storageRef.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      Logger.info('Upload completed. URL: $downloadUrl');

      // Salvează în Firestore
      await _firestore
          .collection('driver_applications')
          .doc(_currentUserId)
          .set({
        documentType.firestoreField: downloadUrl,
        '${documentType.firestoreField}_uploadedAt': FieldValue.serverTimestamp(),
        '${documentType.firestoreField}_fileName': fileName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Logger.debug('Document info saved to Firestore');

      return downloadUrl;
    } catch (e) {
      Logger.error('Error uploading document: $e', error: e);
      rethrow;
    }
  }

  // Șterge document
  Future<void> removeDocument(DriverDocumentType documentType) async {
    if (_currentUserId == null) throw Exception('Utilizator neautentificat');

    try {
      // Șterge din Firestore
      await _firestore
          .collection('driver_applications')
          .doc(_currentUserId)
          .update({
        documentType.firestoreField: FieldValue.delete(),
        '${documentType.firestoreField}_uploadedAt': FieldValue.delete(),
        '${documentType.firestoreField}_fileName': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      Logger.debug('Document ${documentType.displayName} removed from Firestore');
    } catch (e) {
      Logger.error('Error removing document: $e', error: e);
      rethrow;
    }
  }

  // Trimite aplicația pentru aprobare
  Future<void> submitApplication() async {
    if (_currentUserId == null) throw Exception('Utilizator neautentificat');

    try {
      // Verifică dacă aplicația este completă
      final applicationDoc = await _firestore
          .collection('driver_applications')
          .doc(_currentUserId)
          .get();

      if (!applicationDoc.exists) {
        throw Exception('Aplicația nu a fost găsită');
      }

      final applicationData = DriverApplicationData.fromFirestore(applicationDoc.data()!);
      
      if (!applicationData.isComplete) {
        throw Exception('Aplicația nu este completă. Vă rugăm să completați toate câmpurile obligatorii.');
      }

      // Marchează aplicația ca trimisă
      await _firestore
          .collection('driver_applications')
          .doc(_currentUserId)
          .update({
        'status': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Notifică administratorii (opțional - poți adăuga aici logica de notificare)
      await _notifyAdminsOfNewApplication();

      Logger.debug('Driver application submitted successfully');
    } catch (e) {
      Logger.error('Error submitting application: $e', error: e);
      rethrow;
    }
  }

  // Notifică administratorii despre aplicația nouă
  Future<void> _notifyAdminsOfNewApplication() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('admin_notifications').add({
        'type': 'new_driver_application',
        'userId': _currentUserId,
        'userEmail': user.email,
        'message': 'Aplicație nouă pentru șofer partener',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      Logger.debug('Admin notification sent');
    } catch (e) {
      Logger.error('Error sending admin notification: $e', error: e);
      // Nu aruncăm eroarea aici pentru că este o funcție auxiliară
    }
  }

  // Obține aplicația curentă
  Future<DriverApplicationData?> getCurrentApplication() async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('driver_applications')
          .doc(_currentUserId)
          .get();

      if (!doc.exists) return DriverApplicationData();
      
      return DriverApplicationData.fromFirestore(doc.data()!);
    } catch (e) {
      Logger.error('Error getting current application: $e', error: e);
      return null;
    }
  }

  // Verifică dacă utilizatorul are o aplicație în curs
  Future<bool> hasActiveApplication() async {
    if (_currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('driver_applications')
          .doc(_currentUserId)
          .get();

      if (!doc.exists) return false;
      
      final status = doc.data()?['status'] ?? 'draft';
      return ['draft', 'submitted', 'under_review'].contains(status);
    } catch (e) {
      Logger.error('Error checking active application: $e', error: e);
      return false;
    }
  }

  // Resetează aplicația (permite re-aplicarea)
  Future<void> resetApplication() async {
    if (_currentUserId == null) throw Exception('Utilizator neautentificat');

    await _firestore
        .collection('driver_applications')
        .doc(_currentUserId)
        .update({
      'status': 'draft',
      'submittedAt': FieldValue.delete(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    Logger.debug('Application reset for user: $_currentUserId');
  }

  // Obține URL-ul pentru previzualizarea documentului
  String? getDocumentUrl(DriverApplicationData application, DriverDocumentType documentType) {
    return application.documents[documentType]?.url;
  }

  // Verifică dacă documentul este încărcat
  bool isDocumentUploaded(DriverApplicationData application, DriverDocumentType documentType) {
    return application.documents[documentType]?.isUploaded == true;
  }

  // ── Admin: aprobă / respinge un document individual ──────────────────────

  Future<void> updateDocumentStatus(
    String userId,
    DriverDocumentType docType,
    DriverDocumentStatus status, {
    String? reason,
  }) async {
    final updates = <String, dynamic>{
      '${docType.name}_status': status.value,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    if (reason != null && reason.isNotEmpty) {
      updates['${docType.name}_rejectionReason'] = reason;
    } else if (status == DriverDocumentStatus.approved) {
      updates['${docType.name}_rejectionReason'] = FieldValue.delete();
    }

    await _firestore
        .collection('driver_applications')
        .doc(userId)
        .update(updates);

    Logger.debug('Document ${docType.name} status updated to ${status.value} for user $userId');
  }

  // ── Admin: genera și salvează codul de acces ──────────────────────────────

  Future<String> generateAndSendAccessCode(String userId) async {
    final code = (100000 + Random.secure().nextInt(900000)).toString();

    await _firestore
        .collection('driver_applications')
        .doc(userId)
        .update({
      'accessCode': code,
      'accessCodeGeneratedAt': FieldValue.serverTimestamp(),
      'status': 'activated',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    Logger.info('Access code generated for user $userId');
    return code;
  }

  // ── Șofer: setează data de expirare pentru un document ───────────────────

  Future<void> setDocumentExpiryDate(
    DriverDocumentType docType,
    DateTime expiryDate,
  ) async {
    if (_currentUserId == null) throw Exception('Utilizator neautentificat');

    await _firestore
        .collection('driver_applications')
        .doc(_currentUserId)
        .update({
      '${docType.name}_expiryDate': Timestamp.fromDate(expiryDate),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    Logger.debug('Expiry date set for ${docType.name}: $expiryDate');
  }

  // ── Șofer: documente care expiră în 30 de zile ───────────────────────────

  Future<List<DriverDocumentType>> getDocumentsWithExpiryWarning() async {
    final application = await getCurrentApplication();
    if (application == null) return [];

    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 30));
    final expiring = <DriverDocumentType>[];

    for (final entry in application.documents.entries) {
      final expiry = entry.value.expiryDate;
      if (expiry != null && expiry.isAfter(now) && expiry.isBefore(threshold)) {
        expiring.add(entry.key);
      }
    }
    return expiring;
  }

  // ── Șofer: verifică dacă șoferul este blocat din cauza documentelor expirate

  Future<bool> isDriverBlocked() async {
    final application = await getCurrentApplication();
    if (application == null) return false;

    final requiredDocs = DriverDocumentType.values.where((d) => d.isRequired);
    for (final docType in requiredDocs) {
      final doc = application.documents[docType];
      if (doc != null && doc.isExpired) return true;
    }
    return false;
  }
}