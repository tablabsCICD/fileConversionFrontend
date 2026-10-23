import 'dart:typed_data';

/// A file chosen for conversion, decoupled from `file_picker` so the UI can
/// be rendered (and previewed in Widgetbook) without a platform picker.
class SelectedFile {
  final String name;
  final int sizeBytes;

  /// Local path, when the platform provides one (not on web).
  final String? path;

  /// In-memory contents, when there is no path (web).
  final Uint8List? bytes;

  const SelectedFile({
    required this.name,
    required this.sizeBytes,
    this.path,
    this.bytes,
  });
}

/// What a successful conversion produced.
class ConversionResult {
  final String fileName;
  final int sizeBytes;

  /// Where the converted file was written.
  final String? path;

  const ConversionResult({
    required this.fileName,
    required this.sizeBytes,
    this.path,
  });
}

/// Everything the converter screen can show. Each state is rendered by
/// `ConversionPanel`.
sealed class ConversionState {
  const ConversionState();

  List<SelectedFile> get files => const [];
}

/// Nothing picked yet.
class ConversionIdle extends ConversionState {
  const ConversionIdle();
}

/// A picked file does not match the tool's input format.
class ConversionInvalidFile extends ConversionState {
  @override
  final List<SelectedFile> files;
  final String message;
  const ConversionInvalidFile(this.files, this.message);
}

/// Valid files are ready to convert.
class ConversionReady extends ConversionState {
  @override
  final List<SelectedFile> files;
  const ConversionReady(this.files);
}

/// Conversion running. [progress] is null when it cannot be measured.
class ConversionInProgress extends ConversionState {
  @override
  final List<SelectedFile> files;
  final double? progress;
  const ConversionInProgress(this.files, {this.progress});
}

class ConversionSucceeded extends ConversionState {
  @override
  final List<SelectedFile> files;
  final ConversionResult result;
  const ConversionSucceeded(this.files, this.result);
}

class ConversionFailed extends ConversionState {
  @override
  final List<SelectedFile> files;
  final String message;
  const ConversionFailed(this.files, this.message);
}
