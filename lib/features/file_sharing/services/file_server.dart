import 'dart:io';

class FileServer {
  HttpServer? _server;

  /// Number of completed downloads since [start].
  int downloads = 0;

  /// Starts a local HTTP server and exposes the file
  /// Returns the port number
  /// [onDownload] fires each time a receiver finishes downloading.
  Future<int> start(File file, {void Function(int count)? onDownload}) async {
    stop();
    downloads = 0;
    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      0, // auto-pick free port
    );

    _server!.listen((HttpRequest request) async {
      // Browsers ask for a favicon; don't count or serve it.
      if (request.uri.path == '/favicon.ico') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      try {
        final fileName = file.uri.pathSegments.last;
        final fileLength = await file.length();

        request.response.headers
          ..contentType = ContentType.binary
          ..set(
            'content-disposition',
            'attachment; filename="${fileName.replaceAll('"', '')}"; '
                "filename*=UTF-8''${Uri.encodeComponent(fileName)}",
          )
          ..set(HttpHeaders.contentLengthHeader, fileLength);

        // Stream file instead of loading into memory
        await request.response.addStream(file.openRead());
        downloads++;
        onDownload?.call(downloads);
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
      } finally {
        await request.response.close();
      }
    });

    return _server!.port;
  }

  bool get isRunning => _server != null;

  /// Stops the server safely
  void stop() {
    _server?.close(force: true);
    _server = null;
  }
}
