import 'package:flutter/material.dart';

/// Broad family a file format belongs to. Drives colour and iconography so a
/// PDF always reads as a PDF, wherever it appears.
enum FileFamily {
  pdf('PDF', Icons.picture_as_pdf_outlined),
  document('Document', Icons.article_outlined),
  data('Data', Icons.data_object),
  image('Image', Icons.image_outlined),
  video('Video', Icons.movie_outlined),
  audio('Audio', Icons.graphic_eq),
  archive('Archive', Icons.inventory_2_outlined),
  other('File', Icons.insert_drive_file_outlined);

  const FileFamily(this.label, this.icon);

  final String label;
  final IconData icon;

  static const _byExtension = <String, FileFamily>{
    'pdf': pdf,
    'doc': document,
    'docx': document,
    'odt': document,
    'rtf': document,
    'txt': document,
    'html': document,
    'md': data,
    'markdown': data,
    'csv': data,
    'xlsx': data,
    'json': data,
    'xml': data,
    'png': image,
    'jpg': image,
    'jpeg': image,
    'webp': image,
    'bmp': image,
    'tiff': image,
    'gif': image,
    'heic': image,
    'images': image,
    'mp4': video,
    'avi': video,
    'mov': video,
    'mkv': video,
    'webm': video,
    'mp3': audio,
    'wav': audio,
    'aac': audio,
    'ogg': audio,
    'flac': audio,
    'm4a': audio,
    'audio': audio,
    'zip': archive,
    'rar': archive,
    '7z': archive,
    'tar': archive,
    'archive': archive,
  };

  /// Family for an extension such as `pdf`, `.PDF` or `JPEG`.
  static FileFamily fromExtension(String? extension) {
    if (extension == null) return other;
    final key = extension.toLowerCase().replaceFirst('.', '').trim();
    return _byExtension[key] ?? other;
  }

  /// Family for a conversion title such as "PDF to DOCX" (uses the source)
  /// or "Compress Images" (uses the last meaningful word).
  static FileFamily fromConversionTitle(String title) {
    final words = title
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    for (final word in words) {
      final family = fromExtension(word);
      if (family != other) return family;
    }
    return other;
  }
}

/// Small helpers for presenting file metadata.
abstract final class FileFormat {
  /// `report.final.PDF` → `pdf`. Returns null when there is no extension.
  static String? extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return null;
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// 1536 → `1.5 KB`. Uses binary units, one decimal under 10.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final digits = value < 10 ? 1 : 0;
    return '${value.toStringAsFixed(digits)} ${units[unit]}';
  }
}
