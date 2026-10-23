// Pure-Dart, on-device conversions. Everything here runs inside a background
// isolate (see LocalFileConverter), so it must not touch Flutter bindings.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart' as csvlib;
import 'package:excel/excel.dart' as xl;
import 'package:image/image.dart' as img;
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';

/// A user-facing conversion failure.
class ConversionException implements Exception {
  final String message;
  const ConversionException(this.message);
  @override
  String toString() => message;
}

/// One input file, as bytes.
typedef ConversionInput = ({String name, Uint8List bytes});

/// Fonts embedded in generated PDFs (loaded from app assets).
typedef PdfFonts = ({Uint8List mono, Uint8List monoBold, Uint8List serif});

/// What an on-device tool accepts and produces.
class ToolSpec {
  final List<String> inputs;
  final String output;

  /// Accepts several files at once.
  final bool multiple;

  /// Needs [PdfFonts].
  final bool needsFonts;

  const ToolSpec(
    this.inputs,
    this.output, {
    this.multiple = false,
    this.needsFonts = false,
  });
}

/// Catalogue titles that can run on this device, keyed by tool title.
/// Anything not listed needs a server or native codecs and is shown as
/// "coming soon" in the UI.
abstract final class OnDeviceTools {
  static const _images = ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'];

  static const specs = <String, ToolSpec>{
    // Documents
    'DOCX to TXT': ToolSpec(['docx'], 'txt'),
    'DOCX to HTML': ToolSpec(['docx'], 'html'),
    'TXT to PDF': ToolSpec(['txt'], 'pdf', needsFonts: true),
    'TXT to DOCX': ToolSpec(['txt'], 'docx'),
    // Data
    'CSV to XLSX': ToolSpec(['csv'], 'xlsx'),
    'CSV to JSON': ToolSpec(['csv'], 'json'),
    'JSON to CSV': ToolSpec(['json'], 'csv'),
    'XML to JSON': ToolSpec(['xml'], 'json'),
    'JSON to XML': ToolSpec(['json'], 'xml'),
    'Markdown to PDF': ToolSpec(['md'], 'pdf', needsFonts: true),
    'Markdown to HTML': ToolSpec(['md'], 'html'),
    // PNG
    'PNG to JPG': ToolSpec(['png'], 'jpg'),
    'PNG to JPEG': ToolSpec(['png'], 'jpeg'),
    'PNG to BMP': ToolSpec(['png'], 'bmp'),
    'PNG to TIFF': ToolSpec(['png'], 'tiff'),
    'PNG to GIF': ToolSpec(['png'], 'gif'),
    'PNG to PDF': ToolSpec(['png'], 'pdf'),
    // JPG
    'JPG to PNG': ToolSpec(['jpg', 'jpeg'], 'png'),
    'JPG to BMP': ToolSpec(['jpg', 'jpeg'], 'bmp'),
    'JPG to TIFF': ToolSpec(['jpg', 'jpeg'], 'tiff'),
    'JPG to GIF': ToolSpec(['jpg', 'jpeg'], 'gif'),
    'JPG to PDF': ToolSpec(['jpg', 'jpeg'], 'pdf'),
    // Image utilities
    'Images to PDF': ToolSpec(_images, 'pdf', multiple: true),
    'Compress Images': ToolSpec(_images, 'jpg'),
    // Archives
    'TAR to ZIP': ToolSpec(['tar'], 'zip'),
    'Compress Files': ToolSpec([], 'zip', multiple: true),
  };

  static ToolSpec? of(String title) => specs[title];
  static bool supports(String title) => specs.containsKey(title);
}

/// Runs [tool] on [inputs]. Isolate-safe.
Future<Uint8List> runConversion(
  String tool,
  List<ConversionInput> inputs,
  PdfFonts? fonts,
) async {
  if (inputs.isEmpty) throw const ConversionException('No file selected.');
  final first = inputs.first;

  final FutureOr<Uint8List> result = switch (tool) {
    'DOCX to TXT' => _utf8(
      _docxParagraphs(first.bytes).map((p) => p.text).join('\n'),
    ),
    'DOCX to HTML' => _utf8(_docxToHtml(first)),
    'TXT to PDF' => _textToPdf(_text(first), fonts!),
    'TXT to DOCX' => _textToDocx(_text(first)),
    'CSV to XLSX' => _csvToXlsx(_text(first)),
    'CSV to JSON' => _utf8(_csvToJson(_text(first))),
    'JSON to CSV' => _utf8(_jsonToCsv(_text(first))),
    'XML to JSON' => _utf8(_xmlToJson(_text(first))),
    'JSON to XML' => _utf8(_jsonToXml(_text(first))),
    'Markdown to HTML' => _utf8(_markdownToHtml(first)),
    'Markdown to PDF' => _markdownToPdf(_text(first), fonts!),
    'Images to PDF' || 'PNG to PDF' || 'JPG to PDF' => _imagesToPdf(inputs),
    'Compress Images' => _compressImage(first.bytes),
    'TAR to ZIP' => _tarToZip(first.bytes),
    'Compress Files' => _zip(inputs),
    _ when tool.contains(' to ') => _convertImage(
      first.bytes,
      tool.split(' to ').last.toLowerCase(),
    ),
    _ => throw ConversionException('$tool is not available on this device.'),
  };
  return await result;
}

// -----------------------------------------------------------------------------
// TEXT HELPERS
// -----------------------------------------------------------------------------

Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

String _text(ConversionInput input) {
  try {
    return utf8
        .decode(input.bytes, allowMalformed: false)
        .replaceFirst('﻿', '');
  } on FormatException {
    // Fall back to Latin-1 for legacy text files.
    return latin1.decode(input.bytes);
  }
}

String _escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _baseName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot > 0 ? fileName.substring(0, dot) : fileName;
}

const _htmlStyle = '''
body{font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;max-width:46rem;margin:3rem auto;padding:0 1.25rem;color:#17160f;background:#fcfbf7}
h1,h2,h3,h4{line-height:1.2}pre,code{font-family:ui-monospace,Menlo,monospace;background:#eae6dc;border-radius:4px}
pre{padding:1rem;overflow:auto}code{padding:.1em .3em}table{border-collapse:collapse}td,th{border:1px solid #b9b3a5;padding:.3rem .6rem}
blockquote{margin:0;padding-left:1rem;border-left:3px solid #2747d9;color:#5c5950}img{max-width:100%}''';

String _htmlDocument(String title, String body) =>
    '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
    '<meta name="viewport" content="width=device-width,initial-scale=1">\n'
    '<title>${_escapeHtml(title)}</title>\n<style>$_htmlStyle</style>\n'
    '</head>\n<body>\n$body\n</body>\n</html>\n';

// -----------------------------------------------------------------------------
// DOCX
// -----------------------------------------------------------------------------

class _DocxRun {
  final String text;
  final bool bold;
  final bool italic;
  const _DocxRun(this.text, {this.bold = false, this.italic = false});
}

class _DocxParagraph {
  final List<_DocxRun> runs;
  final int heading; // 0 = body
  final bool listItem;
  const _DocxParagraph(this.runs, {this.heading = 0, this.listItem = false});
  String get text => runs.map((r) => r.text).join();
}

List<_DocxParagraph> _docxParagraphs(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const ConversionException('This file is not a valid DOCX document.');
  }
  final entry = archive.findFile('word/document.xml');
  if (entry == null) {
    throw const ConversionException('This DOCX has no document body.');
  }
  final doc = XmlDocument.parse(utf8.decode(entry.content as List<int>));

  bool hasFlag(XmlElement? props, String name) {
    final el = props?.findElements(name).firstOrNull;
    if (el == null) return false;
    final val = el.getAttribute('w:val');
    return val == null || (val != 'false' && val != '0');
  }

  final paragraphs = <_DocxParagraph>[];
  for (final p in doc.findAllElements('w:p')) {
    final pPr = p.findElements('w:pPr').firstOrNull;
    final style =
        pPr?.findElements('w:pStyle').firstOrNull?.getAttribute('w:val') ?? '';
    final heading = RegExp(r'^(?:Heading|heading)\s?(\d)$').firstMatch(style);
    final runs = <_DocxRun>[];
    for (final r in p.findAllElements('w:r')) {
      final rPr = r.findElements('w:rPr').firstOrNull;
      final buffer = StringBuffer();
      for (final child in r.childElements) {
        switch (child.name.qualified) {
          case 'w:t':
            buffer.write(child.innerText);
          case 'w:tab':
            buffer.write('\t');
          case 'w:br' || 'w:cr':
            buffer.write('\n');
        }
      }
      if (buffer.isNotEmpty) {
        runs.add(
          _DocxRun(
            buffer.toString(),
            bold: hasFlag(rPr, 'w:b'),
            italic: hasFlag(rPr, 'w:i'),
          ),
        );
      }
    }
    paragraphs.add(
      _DocxParagraph(
        runs,
        heading: heading == null ? 0 : int.parse(heading.group(1)!).clamp(1, 6),
        listItem: pPr?.findElements('w:numPr').isNotEmpty ?? false,
      ),
    );
  }
  return paragraphs;
}

String _docxToHtml(ConversionInput input) {
  final body = StringBuffer();
  var inList = false;
  for (final p in _docxParagraphs(input.bytes)) {
    final inner = p.runs.map((r) {
      var t = _escapeHtml(r.text).replaceAll('\n', '<br>');
      if (r.italic) t = '<em>$t</em>';
      if (r.bold) t = '<strong>$t</strong>';
      return t;
    }).join();
    if (p.listItem && !inList) {
      body.writeln('<ul>');
      inList = true;
    } else if (!p.listItem && inList) {
      body.writeln('</ul>');
      inList = false;
    }
    if (p.listItem) {
      body.writeln('<li>$inner</li>');
    } else if (p.heading > 0) {
      body.writeln('<h${p.heading}>$inner</h${p.heading}>');
    } else if (inner.isNotEmpty) {
      body.writeln('<p>$inner</p>');
    }
  }
  if (inList) body.writeln('</ul>');
  return _htmlDocument(_baseName(input.name), body.toString());
}

Uint8List _textToDocx(String text) {
  String esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  final paragraphs = const LineSplitter().convert(text).map((line) {
    if (line.isEmpty) return '<w:p/>';
    final parts = line
        .split('\t')
        .map((s) => '<w:t xml:space="preserve">${esc(s)}</w:t>');
    return '<w:p><w:r>${parts.join('<w:tab/>')}</w:r></w:p>';
  }).join();

  const contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>';
  const rels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';
  final document =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>$paragraphs<w:sectPr/></w:body></w:document>';

  return _zip([
    (name: '[Content_Types].xml', bytes: _utf8(contentTypes)),
    (name: '_rels/.rels', bytes: _utf8(rels)),
    (name: 'word/document.xml', bytes: _utf8(document)),
  ]);
}

// -----------------------------------------------------------------------------
// DATA
// -----------------------------------------------------------------------------

List<List<dynamic>> _parseCsv(String text, {bool typed = false}) {
  final rows = csvlib.Csv(dynamicTyping: typed).decode(text);
  if (rows.isEmpty) throw const ConversionException('This CSV file is empty.');
  return rows;
}

String _csvToJson(String text) {
  final rows = _parseCsv(text, typed: true);
  final headers = [
    for (var i = 0; i < rows.first.length; i++)
      '${rows.first[i]}'.trim().isEmpty
          ? 'column_${i + 1}'
          : '${rows.first[i]}'.trim(),
  ];
  final records = [
    for (final row in rows.skip(1))
      {
        for (var i = 0; i < headers.length; i++)
          headers[i]: i < row.length ? row[i] : null,
      },
  ];
  return const JsonEncoder.withIndent('  ').convert(records);
}

Uint8List _csvToXlsx(String text) {
  final rows = _parseCsv(text, typed: true);
  final book = xl.Excel.createExcel();
  final sheet = book[book.getDefaultSheet() ?? 'Sheet1'];
  for (final row in rows) {
    sheet.appendRow([
      for (final cell in row)
        switch (cell) {
          int v => xl.IntCellValue(v),
          double v => xl.DoubleCellValue(v),
          bool v => xl.BoolCellValue(v),
          null => null,
          _ => xl.TextCellValue('$cell'),
        },
    ]);
  }
  final bytes = book.encode();
  if (bytes == null) {
    throw const ConversionException('Could not build the spreadsheet.');
  }
  return Uint8List.fromList(bytes);
}

Object? _parseJson(String text) {
  try {
    return jsonDecode(text);
  } on FormatException catch (e) {
    throw ConversionException('This file is not valid JSON: ${e.message}');
  }
}

String _jsonToCsv(String text) {
  var data = _parseJson(text);
  // Accept {"items": [...]} when the object wraps a single list.
  if (data is Map && data.length == 1 && data.values.first is List) {
    data = data.values.first;
  }
  if (data is Map) data = [data];
  if (data is! List || data.isEmpty) {
    throw const ConversionException(
      'JSON must be a list of objects to become a table.',
    );
  }
  final headers = <String>[];
  for (final item in data) {
    if (item is Map) {
      for (final k in item.keys) {
        if (!headers.contains('$k')) headers.add('$k');
      }
    }
  }
  if (headers.isEmpty) {
    return csvlib.Csv().encode([
      ['value'],
      for (final v in data) [v is String ? v : jsonEncode(v)],
    ]);
  }
  String cell(Object? v) => switch (v) {
    null => '',
    String s => s,
    num _ || bool _ => '$v',
    _ => jsonEncode(v),
  };
  return csvlib.Csv().encode([
    headers,
    for (final item in data)
      [for (final h in headers) cell(item is Map ? item[h] : null)],
  ]);
}

String _xmlToJson(String text) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(text);
  } on XmlException catch (e) {
    throw ConversionException('This file is not valid XML: ${e.message}');
  }

  Object? convert(XmlElement el) {
    final map = <String, Object?>{
      for (final a in el.attributes) '@${a.name.qualified}': a.value,
    };
    final children = el.childElements.toList();
    final text = el.children
        .whereType<XmlText>()
        .map((t) => t.value)
        .join()
        .trim();
    if (children.isEmpty) {
      if (map.isEmpty) return text;
      if (text.isNotEmpty) map['#text'] = text;
      return map;
    }
    for (final child in children) {
      final key = child.name.qualified;
      final value = convert(child);
      if (map.containsKey(key)) {
        final existing = map[key];
        map[key] = existing is List ? [...existing, value] : [existing, value];
      } else {
        map[key] = value;
      }
    }
    if (text.isNotEmpty) map['#text'] = text;
    return map;
  }

  final root = doc.rootElement;
  return const JsonEncoder.withIndent(
    '  ',
  ).convert({root.name.qualified: convert(root)});
}

String _jsonToXml(String text) {
  final data = _parseJson(text);
  String tag(String key) {
    var t = key.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    if (t.isEmpty || RegExp(r'^[^A-Za-z_]').hasMatch(t)) t = '_$t';
    return t;
  }

  final builder = XmlBuilder()
    ..processing('xml', 'version="1.0" encoding="UTF-8"');
  void write(String name, Object? value) {
    if (value is List) {
      for (final v in value) {
        write(name, v);
      }
      return;
    }
    builder.element(
      tag(name),
      nest: () {
        if (value is Map) {
          value.forEach((k, v) => write('$k', v));
        } else if (value != null) {
          builder.text('$value');
        }
      },
    );
  }

  if (data is Map && data.length == 1) {
    write('${data.keys.first}', data.values.first);
  } else {
    builder.element(
      'root',
      nest: () {
        if (data is List) {
          for (final v in data) {
            write('item', v);
          }
        } else if (data is Map) {
          data.forEach((k, v) => write('$k', v));
        } else {
          builder.text('$data');
        }
      },
    );
  }
  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}

String _markdownToHtml(ConversionInput input) => _htmlDocument(
  _baseName(input.name),
  md.markdownToHtml(_text(input), extensionSet: md.ExtensionSet.gitHubWeb),
);

// -----------------------------------------------------------------------------
// PDF
// -----------------------------------------------------------------------------

pw.ThemeData _pdfTheme(PdfFonts fonts) => pw.ThemeData.withFont(
  base: pw.Font.ttf(ByteData.sublistView(fonts.mono)),
  bold: pw.Font.ttf(ByteData.sublistView(fonts.monoBold)),
  italic: pw.Font.ttf(ByteData.sublistView(fonts.mono)),
  boldItalic: pw.Font.ttf(ByteData.sublistView(fonts.monoBold)),
);

Future<Uint8List> _savePdf(pw.Document doc) => doc.save();

Future<Uint8List> _textToPdf(String text, PdfFonts fonts) {
  final lines = const LineSplitter().convert(text.replaceAll('\t', '    '));
  final doc = pw.Document(theme: _pdfTheme(fonts));
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (_) => [
        for (final line in lines)
          pw.Text(
            line.isEmpty ? ' ' : line,
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
          ),
      ],
    ),
  );
  return _savePdf(doc);
}

Future<Uint8List> _markdownToPdf(String text, PdfFonts fonts) {
  final serif = pw.Font.ttf(ByteData.sublistView(fonts.serif));
  final nodes = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
  ).parse(text);
  final widgets = <pw.Widget>[];

  void block(md.Node node, {int depth = 0}) {
    if (node is md.Text) {
      widgets.add(pw.Text(node.text));
      return;
    }
    if (node is! md.Element) return;
    final content = node.textContent;
    switch (node.tag) {
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        final level = int.parse(node.tag.substring(1));
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
            child: pw.Text(
              content,
              style: pw.TextStyle(font: serif, fontSize: 30 - level * 3.0),
            ),
          ),
        );
      case 'p':
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(content, style: const pw.TextStyle(lineSpacing: 3)),
          ),
        );
      case 'ul' || 'ol':
        var i = 1;
        for (final li in node.children ?? const <md.Node>[]) {
          final bullet = node.tag == 'ol' ? '${i++}.' : '•';
          widgets.add(
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 12.0 + depth * 14, bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(width: 18, child: pw.Text(bullet)),
                  pw.Expanded(child: pw.Text(li.textContent)),
                ],
              ),
            ),
          );
        }
      case 'pre':
        widgets.add(
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            color: PdfColor.fromHex('#EAE6DC'),
            child: pw.Text(content, style: const pw.TextStyle(fontSize: 9)),
          ),
        );
      case 'blockquote':
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.only(left: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                  color: PdfColor.fromHex('#2747D9'),
                  width: 2,
                ),
              ),
            ),
            child: pw.Text(content),
          ),
        );
      case 'hr':
        widgets.add(pw.Divider());
      case 'table':
        final rows =
            node.children
                ?.whereType<md.Element>()
                .expand((section) => section.children ?? const <md.Node>[])
                .whereType<md.Element>()
                .map(
                  (tr) => (tr.children ?? const <md.Node>[])
                      .map((c) => c.textContent)
                      .toList(),
                )
                .toList() ??
            [];
        if (rows.isNotEmpty) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.TableHelper.fromTextArray(
                data: rows,
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
        }
      default:
        for (final child in node.children ?? const <md.Node>[]) {
          block(child, depth: depth + 1);
        }
    }
  }

  for (final node in nodes) {
    block(node);
  }
  if (widgets.isEmpty) widgets.add(pw.Text(' '));

  final doc = pw.Document(theme: _pdfTheme(fonts));
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      theme: _pdfTheme(
        fonts,
      ).copyWith(defaultTextStyle: const pw.TextStyle(fontSize: 10.5)),
      build: (_) => widgets,
    ),
  );
  return _savePdf(doc);
}

// -----------------------------------------------------------------------------
// IMAGES
// -----------------------------------------------------------------------------

img.Image _decodeImage(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    throw const ConversionException(
      'This image format could not be read on this device.',
    );
  }
  return decoded;
}

/// Flattens transparency onto white (for formats without alpha).
img.Image _flatten(img.Image src) {
  if (!src.hasAlpha) return src;
  final bg = img.Image(width: src.width, height: src.height);
  img.fill(bg, color: img.ColorRgb8(255, 255, 255));
  return img.compositeImage(bg, src);
}

Uint8List _convertImage(Uint8List bytes, String target) {
  final image = _decodeImage(bytes);
  return switch (target) {
    'jpg' || 'jpeg' => img.encodeJpg(_flatten(image), quality: 92),
    'png' => img.encodePng(image),
    'bmp' => img.encodeBmp(image),
    'tiff' => img.encodeTiff(image),
    'gif' => img.encodeGif(image),
    _ => throw ConversionException(
      'Cannot write .$target images on this device.',
    ),
  };
}

Uint8List _compressImage(Uint8List bytes) {
  var image = _flatten(_decodeImage(bytes));
  const maxSide = 2560;
  if (image.width > maxSide || image.height > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: maxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: maxSide,
            interpolation: img.Interpolation.average,
          );
  }
  return img.encodeJpg(image, quality: 72);
}

Future<Uint8List> _imagesToPdf(List<ConversionInput> inputs) {
  final doc = pw.Document();
  for (final input in inputs) {
    final image = img.bakeOrientation(_decodeImage(input.bytes));
    final jpg = img.encodeJpg(_flatten(image), quality: 90);
    final memory = pw.MemoryImage(jpg);
    final landscape = image.width > image.height;
    doc.addPage(
      pw.Page(
        pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) =>
            pw.Center(child: pw.Image(memory, fit: pw.BoxFit.contain)),
      ),
    );
  }
  return _savePdf(doc);
}

// -----------------------------------------------------------------------------
// ARCHIVES
// -----------------------------------------------------------------------------

Uint8List _zip(List<ConversionInput> files) {
  final archive = Archive();
  final used = <String>{};
  for (final f in files) {
    var name = f.name;
    var n = 2;
    while (!used.add(name)) {
      name =
          '${_baseName(f.name)} ($n)${f.name.contains('.') ? '.${f.name.split('.').last}' : ''}';
      n++;
    }
    archive.addFile(ArchiveFile(name, f.bytes.length, f.bytes));
  }
  final out = ZipEncoder().encode(archive);
  if (out == null) throw const ConversionException('Could not build the ZIP.');
  return Uint8List.fromList(out);
}

Uint8List _tarToZip(Uint8List bytes) {
  final Archive tar;
  try {
    tar = TarDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const ConversionException('This file is not a valid TAR archive.');
  }
  final out = ZipEncoder().encode(tar);
  if (out == null) throw const ConversionException('Could not build the ZIP.');
  return Uint8List.fromList(out);
}
