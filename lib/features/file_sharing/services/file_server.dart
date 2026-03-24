import 'dart:io';

class FileServer {
  HttpServer? _server;

  /// Starts a local HTTP server and exposes the file
  /// Returns the port number
  Future<int> start(File file) async {
    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      0, // auto-pick free port
    );

    _server!.listen((HttpRequest request) async {
      try {
        final fileName = file.uri.pathSegments.last;
        final fileLength = await file.length();

        request.response.headers
          ..contentType = ContentType.binary
          ..set('content-disposition', 'attachment; filename="$fileName"')
          ..set(HttpHeaders.contentLengthHeader, fileLength);

        // Stream file instead of loading into memory
        await request.response.addStream(file.openRead());
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
      } finally {
        await request.response.close();
      }
    });

    return _server!.port;
  }

  /// Stops the server safely
  void stop() {
    _server?.close(force: true);
    _server = null;
  }
}
