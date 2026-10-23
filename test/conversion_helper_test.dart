import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/features/file_conversion/data/helper/conversion_helper.dart';
import 'package:file_convertor/features/file_conversion/data/repositories/conversion_sections_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversionHelper', () {
    test('maps source formats to picker extensions', () {
      expect(ConversionHelper.allowedExtensionsFromTitle('PDF to DOCX'), [
        'pdf',
      ]);
      expect(ConversionHelper.allowedExtensionsFromTitle('JPG to PNG'), [
        'jpg',
        'jpeg',
      ]);
      expect(ConversionHelper.allowedExtensionsFromTitle('DOC to DOCX'), [
        'doc',
      ]);
      expect(ConversionHelper.allowedExtensionsFromTitle('HEIC to JPG'), [
        'heic',
      ]);
      expect(
        ConversionHelper.allowedExtensionsFromTitle('Images to PDF'),
        containsAll(['jpg', 'png']),
      );
      expect(ConversionHelper.allowedExtensionsFromTitle('Compress Files'), []);
    });

    test('every catalogue tool resolves without throwing', () {
      for (final section in conversionSections) {
        for (final item in section.items) {
          ConversionHelper.allowedExtensionsFromTitle(item.title);
          ConversionHelper.formatPairFromTitle(item.title);
        }
      }
    });

    test('splits format pairs and ignores non-pair tools', () {
      expect(ConversionHelper.formatPairFromTitle('PDF to DOCX'), (
        'PDF',
        'DOCX',
      ));
      expect(ConversionHelper.formatPairFromTitle('Audio to Text (Speech)'), (
        'Audio',
        'Text',
      ));
      expect(ConversionHelper.formatPairFromTitle('Compress Images'), isNull);
    });

    test('validates picked files against accepted extensions', () {
      expect(ConversionHelper.isAccepted('Report.PDF', ['pdf']), isTrue);
      expect(ConversionHelper.isAccepted('photo.png', ['pdf']), isFalse);
      expect(ConversionHelper.isAccepted('README', ['md']), isFalse);
      expect(ConversionHelper.isAccepted('anything.bin', []), isTrue);
    });
  });

  group('FileFormat', () {
    test('extracts extensions', () {
      expect(FileFormat.extensionOf('a.b.PDF'), 'pdf');
      expect(FileFormat.extensionOf('.env'), isNull);
      expect(FileFormat.extensionOf('noext'), isNull);
    });

    test('formats byte sizes', () {
      expect(FileFormat.formatBytes(512), '512 B');
      expect(FileFormat.formatBytes(1536), '1.5 KB');
      expect(FileFormat.formatBytes(2457600), '2.3 MB');
      expect(FileFormat.formatBytes(50 * 1024 * 1024), '50 MB');
    });

    test('classifies families', () {
      expect(FileFamily.fromExtension('.JPEG'), FileFamily.image);
      expect(FileFamily.fromExtension('xyz'), FileFamily.other);
      expect(FileFamily.fromConversionTitle('MP4 to GIF'), FileFamily.video);
      expect(
        FileFamily.fromConversionTitle('Compress Images'),
        FileFamily.image,
      );
    });
  });
}
