import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FileClient {
  /// Downloads file from sender
  /// [onProgress] gives 0.0 → 1.0
  static Future<File> download(
    String ip,
    int port, {
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse('http://$ip:$port');
    final request = http.Request('GET', uri);
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception("Failed to download file");
    }

    // Extract filename from headers
    final disposition = response.headers['content-disposition'];
    String fileName = 'received_file';

    if (disposition != null && disposition.contains('filename=')) {
      fileName = disposition.split('filename=').last.replaceAll('"', '');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    final sink = file.openWrite();

    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    await for (final chunk in response.stream) {
      receivedBytes += chunk.length;
      sink.add(chunk);

      if (onProgress != null && totalBytes > 0) {
        onProgress(receivedBytes / totalBytes);
      }
    }

    await sink.flush();
    await sink.close();

    return file;
  }
}
