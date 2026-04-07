import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TrustedContact {
  final String name;
  final String phoneNumber;

  const TrustedContact({
    required this.name,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
      };

  factory TrustedContact.fromJson(Map<String, dynamic> json) => TrustedContact(
        name: json['name'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
      );
}

class SafetyPreferences {
  static const String _trustedContactsKey = 'trusted_contacts';

  static Future<List<TrustedContact>> loadTrustedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_trustedContactsKey);
    if (rawList == null) {
      return const [];
    }
    return rawList
        .map((contactJson) {
          try {
            final Map<String, dynamic> decoded =
                json.decode(contactJson) as Map<String, dynamic>;
            return TrustedContact.fromJson(decoded);
          } catch (_) {
            return null;
          }
        })
        .whereType<TrustedContact>()
        .toList(growable: false);
  }

  static Future<void> saveTrustedContacts(
    List<TrustedContact> contacts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        contacts.map((contact) => json.encode(contact.toJson())).toList();
    await prefs.setStringList(_trustedContactsKey, encoded);
  }

  static Future<void> addTrustedContact(TrustedContact contact) async {
    final contacts = await loadTrustedContacts();
    final updated = [...contacts, contact];
    await saveTrustedContacts(updated);
  }

  static Future<void> removeTrustedContact(TrustedContact contact) async {
    final contacts = await loadTrustedContacts();
    final updated = contacts
        .where((existing) =>
            existing.name != contact.name ||
            existing.phoneNumber != contact.phoneNumber)
        .toList();
    await saveTrustedContacts(updated);
  }
}

