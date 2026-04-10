import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.areaM2,
    required this.estimatedMin,
    required this.estimatedMax,
    required this.usageLabel,
    required this.vigotaLabel,
    required this.finishLabel,
    required this.summary,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final double areaM2;
  final double estimatedMin;
  final double estimatedMax;
  final String usageLabel;
  final String vigotaLabel;
  final String finishLabel;
  final String summary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'areaM2': areaM2,
        'estimatedMin': estimatedMin,
        'estimatedMax': estimatedMax,
        'usageLabel': usageLabel,
        'vigotaLabel': vigotaLabel,
        'finishLabel': finishLabel,
        'summary': summary,
      };

  factory ProjectRecord.fromJson(Map<String, dynamic> json) {
    return ProjectRecord(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      areaM2: (json['areaM2'] as num?)?.toDouble() ?? 0,
      estimatedMin: (json['estimatedMin'] as num?)?.toDouble() ?? 0,
      estimatedMax: (json['estimatedMax'] as num?)?.toDouble() ?? 0,
      usageLabel: (json['usageLabel'] as String?) ?? '',
      vigotaLabel: (json['vigotaLabel'] as String?) ?? '',
      finishLabel: (json['finishLabel'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
    );
  }
}

class ProjectStore {
  static const _key = 'prelaje.projects.v1';

  static Future<void> saveFromCalculation({
    required String id,
    required String name,
    required DateTime createdAt,
    required double areaM2,
    required double estimatedMin,
    required double estimatedMax,
    required String usageLabel,
    required String vigotaLabel,
    required String finishLabel,
    required String summary,
  }) {
    return save(
      ProjectRecord(
        id: id,
        name: name,
        createdAt: createdAt,
        areaM2: areaM2,
        estimatedMin: estimatedMin,
        estimatedMax: estimatedMax,
        usageLabel: usageLabel,
        vigotaLabel: vigotaLabel,
        finishLabel: finishLabel,
        summary: summary,
      ),
    );
  }

  static Future<List<ProjectRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((item) => ProjectRecord.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(ProjectRecord record) async {
    final items = await loadAll();
    items.removeWhere((item) => item.id == record.id);
    items.insert(0, record);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
