import 'package:file_convertor/features/file_conversion/data/services/conversion_engine.dart';

class ConversionHelper {
  static const _imageInputs = ['jpg', 'jpeg', 'png', 'webp', 'heic'];
  static const _audioInputs = ['mp3', 'wav', 'm4a', 'aac'];
  static const _archiveInputs = ['zip', 'rar', '7z', 'tar'];

  /// "DOCX to PDF" → ["docx"]. Empty means any file type is accepted.
  static List<String> allowedExtensionsFromTitle(String title) {
    // On-device tools accept exactly what the engine can read.
    final spec = OnDeviceTools.of(title);
    if (spec != null) return spec.inputs;

    final lower = title.toLowerCase();

    if (lower.startsWith("pdf")) return ["pdf"];
    if (lower.startsWith("docx")) return ["docx"];
    if (lower.startsWith("doc ")) return ["doc"];
    if (lower.startsWith("png")) return ["png"];
    if (lower.startsWith("jpg")) return ["jpg", "jpeg"];
    if (lower.startsWith("heic")) return ["heic"];
    if (lower.startsWith("mp4")) return ["mp4"];
    if (lower.startsWith("mp3")) return ["mp3"];
    if (lower.startsWith("wav")) return ["wav"];
    if (lower.startsWith("m4a")) return ["m4a"];
    if (lower.startsWith("csv")) return ["csv"];
    if (lower.startsWith("json")) return ["json"];
    if (lower.startsWith("xml")) return ["xml"];
    if (lower.startsWith("txt")) return ["txt"];
    if (lower.startsWith("markdown")) return ["md"];
    if (lower.startsWith("zip")) return ["zip"];
    if (lower.startsWith("rar")) return ["rar"];
    if (lower.startsWith("7z")) return ["7z"];
    if (lower.startsWith("tar")) return ["tar"];
    if (lower.startsWith("images") || lower == "compress images") {
      return _imageInputs;
    }
    if (lower.startsWith("audio")) return _audioInputs;
    if (lower.startsWith("extract archive")) return _archiveInputs;

    return [];
  }

  static String subtitleFromTitle(String title) {
    return "Convert ${title.split(' to ').first} files easily.";
  }

  /// "PDF to DOCX" → ("PDF", "DOCX"). Null for tools that are not a
  /// format-to-format conversion, e.g. "Compress Images".
  static (String from, String to)? formatPairFromTitle(String title) {
    final parts = title.split(' to ');
    if (parts.length != 2) return null;
    final to = parts.last.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
    return (parts.first.trim(), to);
  }

  /// Whether [fileName] is acceptable for a tool that takes [allowed]
  /// extensions (empty = anything).
  static bool isAccepted(String fileName, List<String> allowed) {
    if (allowed.isEmpty) return true;
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return false;
    return allowed.contains(fileName.substring(dot + 1).toLowerCase());
  }
}
