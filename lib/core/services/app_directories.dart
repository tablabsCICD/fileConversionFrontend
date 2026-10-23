import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Where the app keeps the files it creates.
///
/// Converted and received files live in Documents (visible in the iOS Files
/// app). The vault lives in Application Support, which is never exposed.
abstract final class AppDirectories {
  static Future<Directory> converted() async => _ensure(
    Directory('${(await getApplicationDocumentsDirectory()).path}/Converted'),
  );

  static Future<Directory> received() async => _ensure(
    Directory('${(await getApplicationDocumentsDirectory()).path}/Received'),
  );

  static Future<Directory> vault() async => _ensure(
    Directory('${(await getApplicationSupportDirectory()).path}/vault'),
  );

  /// Scratch space for decrypted vault previews; wiped on every lock.
  static Future<Directory> vaultPreview() async => _ensure(
    Directory('${(await getTemporaryDirectory()).path}/vault_preview'),
  );

  static Future<Directory> _ensure(Directory dir) async {
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// `dir/name.ext`, or `dir/name (2).ext` if that already exists.
  static Future<File> uniqueFile(Directory dir, String fileName) async {
    final safe = fileName.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    final dot = safe.lastIndexOf('.');
    final base = dot > 0 ? safe.substring(0, dot) : safe;
    final ext = dot > 0 ? safe.substring(dot) : '';
    var candidate = File('${dir.path}/$safe');
    var n = 2;
    while (await candidate.exists()) {
      candidate = File('${dir.path}/$base ($n)$ext');
      n++;
    }
    return candidate;
  }

  /// Total size of every file under [dir] (0 if it does not exist).
  static Future<int> sizeOf(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } on FileSystemException {
          // File vanished mid-scan; ignore.
        }
      }
    }
    return total;
  }
}
