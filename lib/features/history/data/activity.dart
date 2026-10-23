import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityKind {
  converted('Converted', Icons.swap_horiz),
  received('Received', Icons.south_west),
  sent('Shared', Icons.north_east),
  vaulted('Added to vault', Icons.lock_outline);

  const ActivityKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// One thing the user did with a file.
class ActivityEntry {
  final String id;
  final ActivityKind kind;
  final String name;
  final int sizeBytes;

  /// Where the resulting file lives, when the app keeps a copy.
  final String? path;

  /// Extra context, e.g. `PDF → DOCX`.
  final String? detail;
  final DateTime at;

  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.name,
    required this.sizeBytes,
    required this.at,
    this.path,
    this.detail,
  });

  factory ActivityEntry.create({
    required ActivityKind kind,
    required String name,
    required int sizeBytes,
    String? path,
    String? detail,
  }) {
    final now = DateTime.now();
    return ActivityEntry(
      id: '${now.microsecondsSinceEpoch}',
      kind: kind,
      name: name,
      sizeBytes: sizeBytes,
      path: path,
      detail: detail,
      at: now,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'size': sizeBytes,
    'path': path,
    'detail': detail,
    'at': at.toIso8601String(),
  };

  static ActivityEntry? fromJson(Map<String, Object?> json) {
    try {
      return ActivityEntry(
        id: json['id'] as String,
        kind: ActivityKind.values.byName(json['kind'] as String),
        name: json['name'] as String,
        sizeBytes: (json['size'] as num).toInt(),
        path: json['path'] as String?,
        detail: json['detail'] as String?,
        at: DateTime.parse(json['at'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persistent activity log (newest first), stored in SharedPreferences.
class ActivityNotifier extends AsyncNotifier<List<ActivityEntry>> {
  static const _key = 'activity_log_v1';
  static const _limit = 300;

  @override
  Future<List<ActivityEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return [
      for (final item in raw)
        ?ActivityEntry.fromJson(jsonDecode(item) as Map<String, Object?>),
    ];
  }

  Future<void> add(ActivityEntry entry) async {
    final current = await future;
    await _save([entry, ...current].take(_limit).toList());
  }

  Future<void> remove(String id) async {
    final current = await future;
    await _save(current.where((e) => e.id != id).toList());
  }

  Future<void> clear() => _save(const []);

  Future<void> _save(List<ActivityEntry> entries) async {
    state = AsyncData(entries);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [
      for (final e in entries) jsonEncode(e.toJson()),
    ]);
  }
}

final activityProvider =
    AsyncNotifierProvider<ActivityNotifier, List<ActivityEntry>>(
      ActivityNotifier.new,
    );
