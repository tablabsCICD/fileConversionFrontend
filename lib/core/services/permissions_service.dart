import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  /// Only storage/media permission
  static Future<bool> ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+
    final mediaGranted =
        await Permission.photos.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.audio.isGranted;

    if (mediaGranted) return true;

    // Request media permissions
    final mediaStatuses = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    if (mediaStatuses.values.any((p) => p.isGranted)) {
      return true;
    }

    // Android <=12 fallback
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }
}
