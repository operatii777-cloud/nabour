import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/permission_manager.dart';

/// Un contact din agendă care are și cont în aplicație.
class ContactAppUser {
  final String uid;
  final String displayName;
  final String phoneNumber;

  const ContactAppUser({
    required this.uid,
    required this.displayName,
    required this.phoneNumber,
  });
}

/// Reads device contacts, matches phone numbers against Firestore users,
/// and returns the set of UIDs that correspond to registered app contacts.
class ContactsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory cache (avoid re-processing contacts for multiple posts).
  static Set<String>? _uidsCache;
  static DateTime? _uidsCacheAt;
  static const Duration _uidsCacheTtl = Duration(hours: 12);

  static const String _prefsUidsKey = 'cached_contact_uids';
  static const String _prefsTsKey = 'cached_contact_uids_ts';

  /// Clears cached contact→UID resolution (memory + disk). Call after the user's own
  /// `phoneNumber` was fixed in Firestore so the next scan picks up correct matches.
  static Future<void> clearContactUidsCache() async {
    _uidsCache = null;
    _uidsCacheAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsUidsKey);
    await prefs.remove(_prefsTsKey);
  }

  /// Values to write on `users` for phone (canonical duplicate keys help contact matching).
  static Map<String, String> userPhoneFieldsForProfile(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return {'phoneNumber': '', 'phoneE164': ''};
    }
    final trimmed = raw.trim();
    final normalized = normalizePhoneNumber(trimmed);
    final canonical = normalized ?? trimmed;
    return {'phoneNumber': canonical, 'phoneE164': canonical};
  }

  Future<void> _collectUidsForPhoneBatch(List<String> batch, Set<String> out) async {
    if (batch.isEmpty) return;
    try {
      final s1 = await _db.collection('users').where('phoneNumber', whereIn: batch).get();
      for (final d in s1.docs) {
        out.add(d.id);
      }
    } catch (e) {
      Logger.warning('Contacts batch phoneNumber query: $e', tag: 'CONTACTS');
    }
    try {
      final s2 = await _db.collection('users').where('phoneE164', whereIn: batch).get();
      for (final d in s2.docs) {
        out.add(d.id);
      }
    } catch (e) {
      Logger.warning('Contacts batch phoneE164 query: $e', tag: 'CONTACTS');
    }
  }

  /// All `users.phoneNumber` string shapes to try for one raw contact value.
  /// Firestore stores exact string matches; legacy profiles may use national format.
  static Set<String> phoneLookupCandidates(String raw) {
    final out = <String>{};
    final n = normalizePhoneNumber(raw);
    if (n != null) out.add(n);

    var cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)\.\/]'), '');
    if (cleaned.isEmpty) return out;
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    final digits = cleaned.startsWith('+')
        ? cleaned.substring(1).replaceAll(RegExp(r'[^\d]'), '')
        : cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return out;

    if (digits.startsWith('07') && digits.length == 10) {
      out.add(digits);
    }
    if (digits.startsWith('40') && digits.length == 11) {
      out.add('+$digits');
      out.add(digits);
      // ✅ NOU: Adăugăm și formatul local (ex: 07...) pentru matching cu înregistrări Firestore vechi
      out.add('0${digits.substring(2)}');
    }
    if (digits.startsWith('7') && digits.length == 9) {
      out.add('+40$digits');
      out.add('0$digits');
      out.add('40$digits');
    }
    return out;
  }

  static List<ContactAppUser>? _usersCache;
  static DateTime? _usersCacheAt;
  static const String _prefsUsersKey = 'cached_contact_users_json';
  static const String _prefsUsersTsKey = 'cached_contact_users_ts';

  /// Nu afișăm / nu folosim propriul UID ca „contact în agendă” (evită Sugestii → Adaugă la tine).
  static List<ContactAppUser> _withoutSelf(List<ContactAppUser> users) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || myUid.isEmpty) return users;
    return users.where((u) => u.uid != myUid).toList();
  }

  static Set<String> _uidSetWithoutSelf(Set<String> uids) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || myUid.isEmpty) return uids;
    return uids.where((id) => id != myUid).toSet();
  }

  /// Returns app users who are in the device's contact list, with display names.
  Future<List<ContactAppUser>> loadContactUsers({bool forceRefresh = false}) async {
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      if (!forceRefresh) {
        if (_usersCache != null && _usersCacheAt != null && 
            now.difference(_usersCacheAt!) < _uidsCacheTtl) {
          return _withoutSelf(_usersCache!);
        }
        
        final cachedJson = prefs.getStringList(_prefsUsersKey);
        final cachedTs = prefs.getInt(_prefsUsersTsKey);
        if (cachedJson != null && cachedTs != null) {
          final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedTs);
          if (now.difference(cachedAt) < _uidsCacheTtl) {
            _usersCache = cachedJson.map((s) {
              final parts = s.split('|');
              return ContactAppUser(
                uid: parts[0],
                displayName: parts[1],
                phoneNumber: parts[2],
              );
            }).toList();
            _usersCacheAt = cachedAt;
            return _withoutSelf(_usersCache!);
          }
        }
      }

      bool canAccess = await fc.FlutterContacts.permissions.has(fc.PermissionType.read);
      if (!canAccess) {
        final status = await PermissionManager().requestContactsPermission();
        canAccess = status == fc.PermissionStatus.granted || status == fc.PermissionStatus.limited;
      }
      if (!canAccess) return [];

      final contacts = await fc.FlutterContacts.getAll(
        properties: {fc.ContactProperty.phone},
      );

      // Map: exact Firestore phoneNumber string → device contact name
      final phoneToName = <String, String>{};
      for (final contact in contacts) {
        final name = contact.displayName ?? '';
        for (final phone in contact.phones) {
          for (final c in phoneLookupCandidates(phone.number)) {
            phoneToName[c] = name;
          }
        }
      }

      if (phoneToName.isEmpty) return [];

      final result = <ContactAppUser>[];
      final phoneList = phoneToName.keys.toList();
      const batchSize = 30; // Firestore limit is 30 in modern SDKs, was 10. Using 30 for speed.

      for (int i = 0; i < phoneList.length; i += batchSize) {
        final batch = phoneList.skip(i).take(batchSize).toList();
        final byId = <String, Map<String, dynamic>>{};
        
        // Parallel queries for phoneNumber and phoneE164
        final futures = [
          _db.collection('users').where('phoneNumber', whereIn: batch).get(),
          _db.collection('users').where('phoneE164', whereIn: batch).get(),
        ];
        
        final snapshots = await Future.wait(futures);
        for (final snap in snapshots) {
          for (final doc in snap.docs) {
            byId[doc.id] = doc.data();
          }
        }

        for (final entry in byId.entries) {
          final data = entry.value;
          final p = data['phoneNumber'] as String? ?? '';
          final e164 = data['phoneE164'] as String? ?? '';
          final firestoreName = (data['displayName'] as String? ?? '').trim();
          final deviceName = (phoneToName[p] ??
                  phoneToName[e164] ??
                  phoneToName[normalizePhoneNumber(p) ?? ''] ??
                  phoneToName[normalizePhoneNumber(e164) ?? ''] ??
                  '')
              .trim();
          final phone = p.isNotEmpty ? p : e164;
          // Numele din agenda are prioritate pentru persoanele găsite în contacte.
          final displayName = deviceName.isNotEmpty
              ? deviceName
              : (firestoreName.isNotEmpty ? firestoreName : 'Utilizator');
          result.add(ContactAppUser(
            uid: entry.key,
            displayName: displayName,
            phoneNumber: phone,
          ));
        }
      }

      final withoutSelf = _withoutSelf(result);

      // Save to cache (păstrăm lista brută în memorie; la citire filtrăm mereu self-ul)
      _usersCache = result;
      _usersCacheAt = now;
      final jsonList = result.map((u) => '${u.uid}|${u.displayName}|${u.phoneNumber}').toList();
      await prefs.setStringList(_prefsUsersKey, jsonList);
      await prefs.setInt(_prefsUsersTsKey, now.millisecondsSinceEpoch);

      return withoutSelf;
    } catch (e) {
      Logger.error('ContactsService.loadContactUsers: $e', tag: 'CONTACTS', error: e);
      return [];
    }
  }

  /// Returns UIDs of app users who are in the device's contact list.
  /// Returns empty set if permission is denied or no contacts match.
  ///
  /// [forceRefresh] skips memory/disk cache (use before posting ride broadcasts so
  /// `allowedUids` reflects the latest Firestore phone numbers).
  Future<Set<String>> loadContactUids({bool forceRefresh = false}) async {
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      if (forceRefresh) {
        _uidsCache = null;
        _uidsCacheAt = null;
        await prefs.remove(_prefsUidsKey);
        await prefs.remove(_prefsTsKey);
      } else {
        if (_uidsCache != null &&
            _uidsCacheAt != null &&
            now.difference(_uidsCacheAt!) < _uidsCacheTtl) {
          return _uidSetWithoutSelf(_uidsCache!);
        }

        final cachedList = prefs.getStringList(_prefsUidsKey) ?? const <String>[];
        final cachedTsMillis = prefs.getInt(_prefsTsKey);
        if (cachedTsMillis != null) {
          final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedTsMillis);
          if (now.difference(cachedAt) < _uidsCacheTtl) {
            _uidsCache = cachedList.toSet();
            _uidsCacheAt = cachedAt;
            return _uidSetWithoutSelf(_uidsCache!);
          }
        }
      }

      // Check or request permission
      bool canAccess = await fc.FlutterContacts.permissions.has(fc.PermissionType.read);
      if (!canAccess) {
        final status = await PermissionManager().requestContactsPermission();
        canAccess = status == fc.PermissionStatus.granted || status == fc.PermissionStatus.limited;
      }

      if (!canAccess) {
        Logger.info('Contacts permission denied', tag: 'CONTACTS');
        return {};
      }

      final contacts = await fc.FlutterContacts.getAll(
        properties: {fc.ContactProperty.phone},
      );

      final phoneNumbers = <String>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          phoneNumbers.addAll(phoneLookupCandidates(phone.number));
        }
      }

      if (phoneNumbers.isEmpty) return {};

      Logger.info(
        'Found ${phoneNumbers.length} contact phone lookup candidates',
        tag: 'CONTACTS',
      );

      // Query Firestore in batches of 10 (conservative whereIn limit)
      final uids = <String>{};
      final phoneList = phoneNumbers.toList();
      const batchSize = 10;

      for (int i = 0; i < phoneList.length; i += batchSize) {
        final batch = phoneList.skip(i).take(batchSize).toList();
        await _collectUidsForPhoneBatch(batch, uids);
      }

      Logger.info('Found ${uids.length} contacts registered in app', tag: 'CONTACTS');

      // Persist cache for instant posting next time.
      _uidsCache = uids;
      _uidsCacheAt = now;
      await prefs.setStringList(_prefsUidsKey, uids.toList());
      await prefs.setInt(_prefsTsKey, now.millisecondsSinceEpoch);

      return _uidSetWithoutSelf(uids);
    } catch (e) {
      Logger.error('ContactsService error: $e', tag: 'CONTACTS', error: e);
      return {};
    }
  }

  /// Normalizes a phone number to E.164 format (+40XXXXXXXXX for Romanian numbers).
  /// Returns null if the number is too short or unrecognizable.
  static String? normalizePhoneNumber(String raw) {
    // Remove common separators
    String cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)\.\/]'), '');
    if (cleaned.isEmpty) return null;

    // Handle 00 prefix (common European international prefix)
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    // If starts with +, ensure it has enough digits
    if (cleaned.startsWith('+')) {
      return cleaned.length >= 8 ? cleaned : null;
    }

    // Remove any remaining non-digits
    final digits = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;

    // Romanian mobile: 07XXXXXXXX (10 digits)
    if (digits.startsWith('07') && digits.length == 10) {
      return '+4$digits'; // Result: +407...
    }

    // Romanian mobile without leading 0: 7XXXXXXXX (9 digits)
    if (digits.startsWith('7') && digits.length == 9) {
      return '+40$digits';
    }

    // Romanian with country code: 407XXXXXXXX (11 digits)
    if (digits.startsWith('40') && digits.length == 11) {
      return '+$digits';
    }

    // Generic fallback for other international numbers
    if (digits.length >= 10) return '+$digits';

    return null;
  }
}
