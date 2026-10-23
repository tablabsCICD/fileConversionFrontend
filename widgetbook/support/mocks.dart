import 'dart:async';

import 'package:file_convertor/core/services/device_storage_service.dart';
import 'package:file_convertor/core/services/permissions_service.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_section.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_state.dart';
import 'package:file_convertor/features/file_conversion/data/services/conversion_engine.dart';
import 'package:file_convertor/features/file_conversion/data/services/file_converter.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:flutter/material.dart';

/// Story-only converter. Simulates progress and returns a fake result so the
/// full flow can be reviewed without touching the file system.
class DemoFileConverter implements FileConverter {
  DemoFileConverter({this.fail = false, this.reportProgress = true});

  final bool fail;
  final bool reportProgress;

  @override
  bool supports(String toolTitle) => OnDeviceTools.supports(toolTitle);

  @override
  Future<ConversionResult> convert({
    required String toolTitle,
    required List<SelectedFile> files,
    void Function(double progress)? onProgress,
  }) async {
    for (var i = 1; i <= 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (reportProgress) onProgress?.call(i / 20);
      if (fail && i == 13) {
        throw const ConversionException('Demo failure: the file is damaged.');
      }
    }
    final ext = OnDeviceTools.of(toolTitle)?.output ?? 'out';
    final total = files.fold<int>(0, (n, f) => n + f.sizeBytes);
    return ConversionResult(
      fileName: LocalFileConverter.outputName(files, ext),
      sizeBytes: (total * 0.62).round(),
    );
  }
}

/// History pre-filled with sample entries.
class DemoActivityNotifier extends ActivityNotifier {
  DemoActivityNotifier(this.entries);
  final List<ActivityEntry> entries;

  @override
  Future<List<ActivityEntry>> build() async => entries;
}

/// Sample data shared by stories.
abstract final class Fixtures {
  static const pdf = SelectedFile(
    name: 'Quarterly report — final.pdf',
    sizeBytes: 2457600,
  );
  static const png = SelectedFile(name: 'diagram@2x.png', sizeBytes: 812000);
  static const photos = [
    SelectedFile(name: 'IMG_2041.jpg', sizeBytes: 3145728),
    SelectedFile(name: 'IMG_2042.jpg', sizeBytes: 2936012),
    SelectedFile(name: 'whiteboard.png', sizeBytes: 1048576),
  ];
  static const result = ConversionResult(
    fileName: 'Quarterly report — final.docx',
    sizeBytes: 1523712,
  );

  static const pdfToDocx = ConversionItem(
    title: 'PDF to DOCX',
    icon: Icons.description,
    color: Colors.blue,
  );
  static const pngToJpg = ConversionItem(
    title: 'PNG to JPG',
    icon: Icons.image,
    color: Colors.green,
  );

  static List<ActivityEntry> activity() {
    final now = DateTime.now();
    ActivityEntry e(
      ActivityKind k,
      String name,
      int size,
      Duration ago, [
      String? detail,
    ]) => ActivityEntry(
      id: '$name$ago',
      kind: k,
      name: name,
      sizeBytes: size,
      detail: detail,
      at: now.subtract(ago),
    );
    return [
      e(
        ActivityKind.converted,
        'whiteboard.jpg',
        734003,
        const Duration(minutes: 4),
        'PNG to JPG',
      ),
      e(
        ActivityKind.received,
        'Lease agreement.pdf',
        1887436,
        const Duration(hours: 2),
      ),
      e(
        ActivityKind.vaulted,
        'passport-scan.png',
        2411724,
        const Duration(hours: 5),
      ),
      e(
        ActivityKind.sent,
        'holiday.mov',
        48234496,
        const Duration(days: 1, hours: 3),
      ),
      e(
        ActivityKind.converted,
        'budget.xlsx',
        28672,
        const Duration(days: 3),
        'CSV to XLSX',
      ),
    ];
  }

  static StorageSnapshot storage(MediaAccess access, {bool capacity = true}) {
    const gb = 1024 * 1024 * 1024;
    final readable =
        access == MediaAccess.full || access == MediaAccess.limited;
    return StorageSnapshot(
      capacity: capacity
          ? const StorageCapacity(totalBytes: 128 * gb, freeBytes: 37 * gb)
          : null,
      media: readable
          ? (
              images: MediaUsage(
                bytes: access == MediaAccess.limited
                    ? 180 * 1024 * 1024
                    : 21 * gb,
                count: access == MediaAccess.limited ? 42 : 9841,
              ),
              videos: MediaUsage(
                bytes: access == MediaAccess.limited ? 0 : 34 * gb,
                count: access == MediaAccess.limited ? 0 : 412,
              ),
              audio: const MediaUsage(bytes: 3 * gb, count: 1210),
            )
          : null,
      access: access,
      app: const AppUsage(
        converted: 18 * 1024 * 1024,
        received: 64 * 1024 * 1024,
        vault: 212 * 1024 * 1024,
      ),
      takenAt: DateTime.now(),
    );
  }
}
