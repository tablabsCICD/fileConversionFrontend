import 'dart:io';
import 'dart:isolate';

import 'package:file_convertor/core/services/app_directories.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_state.dart';
import 'package:file_convertor/features/file_conversion/data/services/conversion_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Converts files for a catalogue tool.
abstract interface class FileConverter {
  /// Whether [toolTitle] can run with this converter.
  bool supports(String toolTitle);

  Future<ConversionResult> convert({
    required String toolTitle,
    required List<SelectedFile> files,
    void Function(double progress)? onProgress,
  });
}

/// Runs supported tools on-device in a background isolate and writes the
/// result to the app's Converted folder.
class LocalFileConverter implements FileConverter {
  const LocalFileConverter();

  @override
  bool supports(String toolTitle) => OnDeviceTools.supports(toolTitle);

  @override
  Future<ConversionResult> convert({
    required String toolTitle,
    required List<SelectedFile> files,
    void Function(double progress)? onProgress,
  }) async {
    final spec = OnDeviceTools.of(toolTitle);
    if (spec == null) {
      throw ConversionException(
        '$toolTitle is not available on this device yet.',
      );
    }

    final inputs = <ConversionInput>[];
    for (final f in files) {
      inputs.add((name: f.name, bytes: await _read(f)));
    }
    final fonts = spec.needsFonts ? await _loadFonts() : null;

    final Uint8List output;
    try {
      output = await Isolate.run(() => runConversion(toolTitle, inputs, fonts));
    } on ConversionException {
      rethrow;
    } catch (_) {
      throw const ConversionException(
        'Something went wrong while converting. The file may be damaged.',
      );
    }

    final dir = await AppDirectories.converted();
    final file = await AppDirectories.uniqueFile(
      dir,
      outputName(files, spec.output),
    );
    await file.writeAsBytes(output, flush: true);
    return ConversionResult(
      fileName: file.uri.pathSegments.last,
      sizeBytes: output.length,
      path: file.path,
    );
  }

  /// `report.pdf` → `report.docx`; several files → `photo +2.pdf`.
  static String outputName(List<SelectedFile> files, String ext) {
    final first = files.first.name;
    final dot = first.lastIndexOf('.');
    final base = dot > 0 ? first.substring(0, dot) : first;
    final suffix = files.length > 1 ? ' +${files.length - 1}' : '';
    return '$base$suffix.$ext';
  }

  static Future<Uint8List> _read(SelectedFile f) async {
    if (f.bytes != null) return f.bytes!;
    if (f.path == null) {
      throw ConversionException('“${f.name}” could not be read.');
    }
    try {
      return await File(f.path!).readAsBytes();
    } on FileSystemException {
      throw ConversionException('“${f.name}” could not be read.');
    }
  }

  static Future<PdfFonts> _loadFonts() async {
    Future<Uint8List> load(String name) async =>
        (await rootBundle.load('assets/fonts/$name')).buffer.asUint8List();
    return (
      mono: await load('IBMPlexMono-Regular.ttf'),
      monoBold: await load('IBMPlexMono-SemiBold.ttf'),
      serif: await load('InstrumentSerif-Regular.ttf'),
    );
  }
}

final fileConverterProvider = Provider<FileConverter>(
  (ref) => const LocalFileConverter(),
);
