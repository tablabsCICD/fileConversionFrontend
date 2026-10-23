import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_convertor/features/file_conversion/data/helper/conversion_helper.dart';
import 'package:file_convertor/features/file_conversion/data/repositories/conversion_sections_list.dart';
import 'package:file_convertor/features/file_conversion/data/services/conversion_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

ConversionInput _text(String name, String content) =>
    (name: name, bytes: Uint8List.fromList(utf8.encode(content)));

PdfFonts _fonts() {
  Uint8List read(String f) => File('assets/fonts/$f').readAsBytesSync();
  return (
    mono: read('IBMPlexMono-Regular.ttf'),
    monoBold: read('IBMPlexMono-SemiBold.ttf'),
    serif: read('InstrumentSerif-Regular.ttf'),
  );
}

bool _isPdf(Uint8List b) => latin1.decode(b.sublist(0, 5)) == '%PDF-';

ConversionInput _png() {
  final image = img.Image(width: 40, height: 24, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(39, 71, 217, 128));
  return (name: 'logo.png', bytes: img.encodePng(image));
}

void main() {
  test('every on-device tool exists in the catalogue', () {
    final titles = {
      for (final s in conversionSections) ...s.items.map((i) => i.title),
    };
    for (final tool in OnDeviceTools.specs.keys) {
      expect(titles, contains(tool));
    }
  });

  test('tool inputs agree with the picker extensions', () {
    for (final entry in OnDeviceTools.specs.entries) {
      if (entry.value.inputs.isEmpty) continue;
      expect(
        ConversionHelper.allowedExtensionsFromTitle(entry.key),
        entry.value.inputs,
        reason: entry.key,
      );
    }
  });

  group('data', () {
    test('CSV ↔ JSON round trip keeps types', () async {
      final json = await runConversion('CSV to JSON', [
        _text(
          'people.csv',
          'name,age,active\nAda,36,true\n"Lin, Grace",85,false\n',
        ),
      ], null);
      final records = jsonDecode(utf8.decode(json)) as List;
      expect(records.first, {'name': 'Ada', 'age': 36, 'active': true});
      expect(records.last['name'], 'Lin, Grace');

      final csv = await runConversion('JSON to CSV', [
        (name: 'people.json', bytes: json),
      ], null);
      expect(utf8.decode(csv), startsWith('name,age,active'));
      expect(utf8.decode(csv), contains('"Lin, Grace"'));
    });

    test('CSV → XLSX produces a readable workbook', () async {
      final bytes = await runConversion('CSV to XLSX', [
        _text('t.csv', 'a,b\n1,2.5\n'),
      ], null);
      final book = xl.Excel.decodeBytes(bytes);
      final sheet = book.tables.values.first;
      expect(sheet.maxRows, 2);
    });

    test('XML ↔ JSON', () async {
      final json = await runConversion('XML to JSON', [
        _text(
          'a.xml',
          '<lib><book id="1">Dune</book><book id="2">Emma</book></lib>',
        ),
      ], null);
      final data = jsonDecode(utf8.decode(json)) as Map;
      expect((data['lib']['book'] as List).length, 2);
      expect(data['lib']['book'][0], {'@id': '1', '#text': 'Dune'});

      final xml = await runConversion('JSON to XML', [
        _text('a.json', '{"lib": {"book": ["Dune", "Emma"]}}'),
      ], null);
      expect(utf8.decode(xml), contains('<book>Dune</book>'));
    });

    test('invalid JSON reports a readable error', () {
      expect(
        () => runConversion('JSON to CSV', [_text('x.json', '{oops')], null),
        throwsA(isA<ConversionException>()),
      );
    });

    test('Markdown → HTML', () async {
      final html = await runConversion('Markdown to HTML', [
        _text('notes.md', '# Title\n\n- **bold** item\n'),
      ], null);
      expect(utf8.decode(html), contains('Title</h1>'));
      expect(utf8.decode(html), contains('<strong>bold</strong>'));
    });
  });

  group('documents', () {
    test('TXT → DOCX → TXT round trip', () async {
      final docx = await runConversion('TXT to DOCX', [
        _text('memo.txt', 'Hello <world>\n\nSecond\tline'),
      ], null);
      final back = await runConversion('DOCX to TXT', [
        (name: 'memo.docx', bytes: docx),
      ], null);
      expect(utf8.decode(back), 'Hello <world>\n\nSecond\tline');

      final html = await runConversion('DOCX to HTML', [
        (name: 'memo.docx', bytes: docx),
      ], null);
      expect(utf8.decode(html), contains('<p>Hello &lt;world&gt;</p>'));
    });

    test('TXT and Markdown → PDF', () async {
      final fonts = _fonts();
      expect(
        _isPdf(
          await runConversion('TXT to PDF', [
            _text('a.txt', 'Grüße — ok'),
          ], fonts),
        ),
        isTrue,
      );
      expect(
        _isPdf(
          await runConversion('Markdown to PDF', [
            _text('a.md', '# Hi\n\nText\n\n1. one\n2. two\n\n```\ncode\n```\n'),
          ], fonts),
        ),
        isTrue,
      );
    });
  });

  group('images', () {
    test('PNG → JPG/BMP/TIFF/GIF decode back', () async {
      for (final target in ['JPG', 'BMP', 'TIFF', 'GIF']) {
        final out = await runConversion('PNG to $target', [_png()], null);
        final decoded = img.decodeImage(out);
        expect(decoded?.width, 40, reason: target);
      }
    });

    test('images → multi-page PDF, compress → JPG', () async {
      final pdf = await runConversion('Images to PDF', [_png(), _png()], null);
      expect(_isPdf(pdf), isTrue);
      final jpg = await runConversion('Compress Images', [_png()], null);
      expect(img.decodeJpg(jpg), isNotNull);
    });

    test('unreadable image reports a readable error', () {
      expect(
        () => runConversion('PNG to JPG', [_text('bad.png', 'nope')], null),
        throwsA(isA<ConversionException>()),
      );
    });
  });

  group('archives', () {
    test('files → ZIP with unique names, TAR → ZIP', () async {
      final zip = await runConversion('Compress Files', [
        _text('a.txt', 'one'),
        _text('a.txt', 'two'),
      ], null);
      final names = ZipDecoder().decodeBytes(zip).files.map((f) => f.name);
      expect(names, ['a.txt', 'a (2).txt']);

      final tar = TarEncoder().encode(
        Archive()..addFile(ArchiveFile('x.txt', 3, utf8.encode('abc'))),
      );
      final fromTar = await runConversion('TAR to ZIP', [
        (name: 'x.tar', bytes: Uint8List.fromList(tar)),
      ], null);
      expect(ZipDecoder().decodeBytes(fromTar).files.single.name, 'x.txt');
    });
  });
}
