import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

/// Opening and exporting files the app produced.
abstract final class FileActions {
  /// Opens [path] in the system viewer. Returns an error message, or null on
  /// success.
  static Future<String?> open(String path) async {
    if (!await File(path).exists()) return 'This file no longer exists.';
    final result = await OpenFilex.open(path);
    return switch (result.type) {
      ResultType.done => null,
      ResultType.noAppToOpen => 'No app on this device can open this file.',
      ResultType.fileNotFound => 'This file no longer exists.',
      ResultType.permissionDenied => 'Permission to open this file was denied.',
      ResultType.error => result.message,
    };
  }

  /// Lets the user save a copy of [bytes] anywhere (Files, Downloads, Drive…).
  /// Returns the chosen location, or null if they cancelled.
  static Future<String?> saveCopy({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : null;
    final target = await FilePicker.platform.saveFile(
      dialogTitle: 'Save a copy',
      fileName: fileName,
      bytes: bytes,
      type: ext == null ? FileType.any : FileType.custom,
      allowedExtensions: ext == null ? null : [ext],
    );
    // Desktop pickers return a path without writing the bytes.
    if (target != null && !kIsWeb && _isDesktop) {
      final file = File(target);
      if (!await file.exists() || await file.length() != bytes.length) {
        await file.writeAsBytes(bytes, flush: true);
      }
    }
    return target;
  }

  static Future<String?> saveCopyOf(String path, {String? fileName}) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return saveCopy(
      fileName: fileName ?? file.uri.pathSegments.last,
      bytes: await file.readAsBytes(),
    );
  }

  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}
