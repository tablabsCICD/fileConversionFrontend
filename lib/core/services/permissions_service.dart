import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Access to the device's shared media (photos, videos, audio).
enum MediaAccess {
  /// All media is readable.
  full,

  /// Android 14+: the user picked specific photos/videos only.
  limited,

  /// Not granted yet; asking again will show the system prompt.
  denied,

  /// Denied with "don't ask again"; only Settings can change it.
  permanentlyDenied,

  /// The platform has no such permission (iOS, desktop, web).
  notApplicable,
}

class PermissionsService {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _mediaPermissions = [
    Permission.photos,
    Permission.videos,
    Permission.audio,
  ];

  /// Current media access without prompting.
  static Future<MediaAccess> status() async {
    if (!_isAndroid) return MediaAccess.notApplicable;
    final statuses = [
      for (final p in _mediaPermissions) await p.status,
      await Permission.storage.status,
    ];
    return _combine(statuses);
  }

  /// Prompts for media access (Android 13+ media permissions, falling back
  /// to legacy storage on Android 12 and below).
  static Future<MediaAccess> request() async {
    if (!_isAndroid) return MediaAccess.notApplicable;

    final media = await _mediaPermissions.request();
    final combined = _combine(media.values.toList());
    if (combined == MediaAccess.full || combined == MediaAccess.limited) {
      return combined;
    }

    // Android <= 12
    final storage = await Permission.storage.request();
    return _combine([...media.values, storage]);
  }

  /// Kept for the splash flow: true when any media access is available.
  static Future<bool> ensureStoragePermission() async {
    final access = await request();
    return access == MediaAccess.full ||
        access == MediaAccess.limited ||
        access == MediaAccess.notApplicable;
  }

  static MediaAccess _combine(List<PermissionStatus> statuses) {
    if (statuses.any((s) => s.isGranted)) return MediaAccess.full;
    if (statuses.any((s) => s.isLimited)) return MediaAccess.limited;
    if (statuses.any((s) => s.isPermanentlyDenied)) {
      return MediaAccess.permanentlyDenied;
    }
    return MediaAccess.denied;
  }
}
