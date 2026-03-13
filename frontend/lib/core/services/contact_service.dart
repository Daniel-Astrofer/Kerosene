import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Contact {
  final String address;
  final String? name;
  final DateTime lastUsed;

  Contact({required this.address, this.name, required this.lastUsed});

  Map<String, dynamic> toJson() => {
    'address': address,
    'name': name,
    'lastUsed': lastUsed.toIso8601String(),
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    address: json['address'],
    name: json['name'],
    lastUsed: DateTime.parse(json['lastUsed']),
  );
}

class ContactService {
  static const String _storageKey = 'recent_contacts';
  static const int _maxContacts = 10;

  Future<void> saveContact(String address, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getContacts();

    // Remove if already exists to update its position/name
    contacts.removeWhere((c) => c.address == address);

    contacts.insert(
      0,
      Contact(address: address, name: name, lastUsed: DateTime.now()),
    );

    // Limit size
    if (contacts.length > _maxContacts) {
      contacts.removeRange(_maxContacts, contacts.length);
    }

    final jsonList = contacts.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  Future<List<Contact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    return jsonList.map((j) => Contact.fromJson(jsonDecode(j))).toList();
  }
}
