import 'package:file_convertor/core/services/app_directories.dart';
import 'package:file_convertor/core/services/permissions_service.dart';
import 'package:flutter/services.dart';

class StorageCapacity {
  final int totalBytes;
  final int freeBytes;

  const StorageCapacity({required this.totalBytes, required this.freeBytes});

  int get usedBytes => (totalBytes - freeBytes).clamp(0, totalBytes);
  double get usedFraction => totalBytes == 0 ? 0 : usedBytes / totalBytes;
}

class MediaUsage {
  final int bytes;
  final int count;

  const MediaUsage({required this.bytes, required this.count});

  static MediaUsage fromMap(Object? raw) {
    final map = (raw as Map?) ?? const {};
    return MediaUsage(
      bytes: (map['bytes'] as num?)?.toInt() ?? 0,
      count: (map['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Space used by this app's own folders.
class AppUsage {
  final int converted;
  final int received;
  final int vault;

  const AppUsage({
    required this.converted,
    required this.received,
    required this.vault,
  });

  int get total => converted + received + vault;
}

/// Everything the storage screen shows, captured at one moment.
class StorageSnapshot {
  /// Null when the platform cannot report capacity (web).
  final StorageCapacity? capacity;

  /// Null when unavailable (iOS sandbox) or not permitted.
  final ({MediaUsage images, MediaUsage videos, MediaUsage audio})? media;

  final MediaAccess access;
  final AppUsage app;
  final DateTime takenAt;

  const StorageSnapshot({
    required this.capacity,
    required this.media,
    required this.access,
    required this.app,
    required this.takenAt,
  });
}

/// Reads real device storage figures through the `file_convertor/storage`
/// platform channel (see MainActivity.kt and AppDelegate.swift).
class DeviceStorageService {
  const DeviceStorageService();

  static const _channel = MethodChannel('file_convertor/storage');

  Future<StorageCapacity?> capacity() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'getCapacity',
      );
      if (raw == null) return null;
      final total = (raw['totalBytes'] as num?)?.toInt() ?? 0;
      if (total <= 0) return null;
      return StorageCapacity(
        totalBytes: total,
        freeBytes: (raw['freeBytes'] as num?)?.toInt() ?? 0,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<({MediaUsage images, MediaUsage videos, MediaUsage audio})?>
  mediaUsage() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'getMediaUsage',
      );
      if (raw == null) return null;
      return (
        images: MediaUsage.fromMap(raw['images']),
        videos: MediaUsage.fromMap(raw['videos']),
        audio: MediaUsage.fromMap(raw['audio']),
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<AppUsage> appUsage() async {
    final sizes = await Future.wait([
      AppDirectories.converted().then(AppDirectories.sizeOf),
      AppDirectories.received().then(AppDirectories.sizeOf),
      AppDirectories.vault().then(AppDirectories.sizeOf),
    ]);
    return AppUsage(converted: sizes[0], received: sizes[1], vault: sizes[2]);
  }

  Future<StorageSnapshot> snapshot() async {
    final access = await PermissionsService.status();
    final canReadMedia =
        access == MediaAccess.full || access == MediaAccess.limited;
    final results = await Future.wait<Object?>([
      capacity(),
      canReadMedia ? mediaUsage() : Future.value(null),
      appUsage().catchError(
        (_) => const AppUsage(converted: 0, received: 0, vault: 0),
      ),
    ]);
    return StorageSnapshot(
      capacity: results[0] as StorageCapacity?,
      media:
          results[1]
              as ({MediaUsage images, MediaUsage videos, MediaUsage audio})?,
      access: access,
      app: results[2] as AppUsage,
      takenAt: DateTime.now(),
    );
  }
}
