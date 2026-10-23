import 'dart:async';
import 'dart:io';

import 'package:file_convertor/core/services/app_directories.dart';
import 'package:http/http.dart' as http;

class FileClient {
  /// Downloads file from sender into the app's Received folder.
  /// [onProgress] gives 0.0 → 1.0 (only when the sender reports a size).
  static Future<File> download(
    String ip,
    int port, {
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse('http://$ip:$port');
    final client = http.Client();
    try {
      final response = await client
          .send(http.Request('GET', uri))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('No response from sender'),
          );

      if (response.statusCode != 200) {
        throw HttpException('Sender replied ${response.statusCode}', uri: uri);
      }

      final dir = await AppDirectories.received();
      final file = await AppDirectories.uniqueFile(
        dir,
        _fileName(response.headers['content-disposition']),
      );
      final sink = file.openWrite();

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      try {
        await for (final chunk in response.stream) {
          receivedBytes += chunk.length;
          sink.add(chunk);

          if (onProgress != null && totalBytes > 0) {
            onProgress(receivedBytes / totalBytes);
          }
        }
        await sink.flush();
      } catch (_) {
        await sink.close();
        if (await file.exists()) await file.delete();
        rethrow;
      }
      await sink.close();
      return file;
    } finally {
      client.close();
    }
  }

  /// Extracts the file name, preferring the RFC 5987 UTF-8 form.
  static String _fileName(String? disposition) {
    if (disposition == null) return 'received_file';
    final utf = RegExp(r"filename\*=UTF-8''([^;]+)").firstMatch(disposition);
    if (utf != null) return Uri.decodeComponent(utf.group(1)!.trim());
    final plain = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return plain?.group(1)?.trim() ?? 'received_file';
  }
}
