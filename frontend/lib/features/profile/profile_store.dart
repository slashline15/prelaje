import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.company,
    required this.phone,
    required this.crea,
    required this.cityUf,
    required this.logoPath,
    required this.updatedAt,
  });

  final String name;
  final String company;
  final String phone;
  final String crea;
  final String cityUf;
  final String logoPath;
  final DateTime updatedAt;

  String get displayTitle => company.isNotEmpty ? company : name;

  Map<String, dynamic> toJson() => {
        'name': name,
        'company': company,
        'phone': phone,
        'crea': crea,
        'cityUf': cityUf,
        'logoPath': logoPath,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: (json['name'] as String?) ?? '',
      company: (json['company'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      crea: (json['crea'] as String?) ?? '',
      cityUf: (json['cityUf'] as String?) ?? '',
      logoPath: (json['logoPath'] as String?) ?? '',
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class ProfileStore {
  static const _key = 'prelaje.profile.v1';

  static Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
