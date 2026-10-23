import 'package:file_convertor/app/theme/app_theme.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/drop_zone.dart';
import 'package:file_convertor/core/widgets/segmented_toggle.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_section.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_state.dart';
import 'package:file_convertor/features/file_conversion/view/file_conversion_page.dart';
import 'package:file_convertor/features/file_conversion/view/file_upload_page.dart';
import 'package:file_convertor/features/file_conversion/widgets/conversion_panel.dart';
import 'package:file_convertor/features/file_sharing/view/file_sharing_home_page.dart';
import 'package:file_convertor/features/profile/view/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _pdf = SelectedFile(name: 'report.pdf', sizeBytes: 2457600);
const _result = ConversionResult(fileName: 'report.docx', sizeBytes: 1523712);

Widget _app(Widget child, {ThemeData? theme}) => ProviderScope(
  child: MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(body: child),
  ),
);

Widget _panel(
  ConversionState state, {
  bool engine = true,
  VoidCallback? onConvert,
}) => SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: ConversionPanel(
    state: state,
    toolTitle: 'PDF to DOCX',
    targetFormat: 'DOCX',
    acceptedFormats: const ['pdf'],
    engineAvailable: engine,
    onPick: () {},
    onRemove: (_) {},
    onOpen: () {},
    onSave: () {},
    onConvert: onConvert ?? () {},
    onRetry: () {},
    onReset: () {},
  ),
);

void _useViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('ConversionPanel', () {
    testWidgets('renders every state', (tester) async {
      final cases = <ConversionState, String>{
        const ConversionIdle(): 'Choose a file',
        const ConversionInvalidFile([_pdf], 'Needs a .pdf file'):
            'Needs a .pdf file',
        const ConversionReady([_pdf]): 'Convert to DOCX',
        const ConversionInProgress([_pdf], progress: 0.5): '50%',
        const ConversionSucceeded([_pdf], _result): 'Converted.',
        const ConversionFailed([_pdf], 'Corrupt file'): 'Conversion failed',
      };
      for (final entry in cases.entries) {
        await tester.pumpWidget(_app(_panel(entry.key)));
        // In-progress shows an indeterminate spinner, so never "settles".
        await tester.pump(const Duration(seconds: 1));
        expect(find.textContaining(entry.value), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('convert fires only when ready and engine is connected', (
      tester,
    ) async {
      var converted = 0;
      await tester.pumpWidget(
        _app(
          _panel(const ConversionReady([_pdf]), onConvert: () => converted++),
        ),
      );
      await tester.tap(find.text('Convert to DOCX'));
      expect(converted, 1);

      await tester.pumpWidget(
        _app(
          _panel(
            const ConversionReady([_pdf]),
            engine: false,
            onConvert: () => converted++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available on this device yet'), findsOneWidget);
      await tester.tap(find.text('Convert to DOCX'), warnIfMissed: false);
      expect(converted, 1);
    });

    testWidgets('meets tap-target, label and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        for (final state in const <ConversionState>[
          ConversionReady([_pdf]),
          ConversionSucceeded([_pdf], _result),
          ConversionFailed([_pdf], 'Corrupt file'),
        ]) {
          await tester.pumpWidget(_app(_panel(state), theme: theme));
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
      }
      handle.dispose();
    });
  });

  group('Converter screen', () {
    Future<void> pump(WidgetTester tester, String title) async {
      await tester.pumpWidget(
        _app(
          FileUploadPage(
            item: ConversionItem(
              title: title,
              icon: Icons.description,
              color: Colors.blue,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    TextButton convertButton(WidgetTester tester, String label) =>
        tester.widget<TextButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(TextButton),
          ),
        );

    testWidgets('tools that need a server say so and cannot start', (
      tester,
    ) async {
      await pump(tester, 'PDF to DOCX');
      expect(find.text('Not available on this device yet'), findsOneWidget);
      expect(convertButton(tester, 'Convert to DOCX').onPressed, isNull);
    });

    testWidgets('on-device tools are ready once files are picked', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const FileUploadPage(
            item: ConversionItem(
              title: 'PNG to JPG',
              icon: Icons.image,
              color: Colors.green,
            ),
            initialFiles: [SelectedFile(name: 'a.png', sizeBytes: 10)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available on this device yet'), findsNothing);
      expect(convertButton(tester, 'Convert to JPG').onPressed, isNotNull);
    });

    testWidgets('a wrong file type is rejected with a reason', (tester) async {
      await tester.pumpWidget(
        _app(
          const FileUploadPage(
            item: ConversionItem(
              title: 'PNG to JPG',
              icon: Icons.image,
              color: Colors.green,
            ),
            initialFiles: [SelectedFile(name: 'notes.txt', sizeBytes: 10)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('not .txt'), findsOneWidget);
      expect(convertButton(tester, 'Convert to JPG').onPressed, isNull);
    });
  });

  group('Tool catalogue', () {
    testWidgets('search filters tools and shows an empty state', (
      tester,
    ) async {
      _useViewport(tester, const Size(1280, 2400));
      await tester.pumpWidget(_app(const FileConversionPage()));
      await tester.pumpAndSettle();
      expect(find.text('PDF to DOCX'), findsOneWidget);
      expect(find.text('MP3 to WAV'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'mp3');
      await tester.pumpAndSettle();
      expect(find.text('MP3 to WAV'), findsOneWidget);
      expect(find.text('PDF to DOCX'), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'pptx');
      await tester.pumpAndSettle();
      expect(find.text('No matching tools'), findsOneWidget);

      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('PDF to DOCX'), findsOneWidget);
    });
  });

  group('Components', () {
    testWidgets('AppButton is disabled while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Center(
            child: AppButton(
              label: 'Save',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Save'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('DropZone exposes one labelled button', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 400,
              child: DropZone(onTap: () => taps++, formats: const ['pdf']),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(DropZone)),
        matchesSemantics(
          label: 'Choose a file. Accepts PDF',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      await tester.tap(find.byType(DropZone));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('SegmentedToggle reports the tapped segment', (tester) async {
      int? picked;
      await tester.pumpWidget(
        _app(
          Center(
            child: SegmentedToggle(
              segments: const ['Convert', 'Storage'],
              selectedIndex: 0,
              onChanged: (i) => picked = i,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Storage'));
      expect(picked, 1);
    });
  });

  group('Responsive layouts', () {
    const screens = <String, Widget>{
      'Catalogue': FileConversionPage(),
      'Share hub': FileSharingHomePage(),
      'Profile': ProfilePage(),
      'Converter': FileUploadPage(
        item: ConversionItem(
          title: 'Images to PDF',
          icon: Icons.image,
          color: Colors.green,
        ),
      ),
    };
    for (final size in const [
      Size(320, 640),
      Size(800, 1000),
      Size(1440, 900),
    ]) {
      for (final MapEntry(key: name, value: screen) in screens.entries) {
        testWidgets('$name renders without overflow at $size', (tester) async {
          _useViewport(tester, size);
          await tester.pumpWidget(_app(screen));
          await tester.pumpAndSettle();
        });
      }
    }
  });
}
