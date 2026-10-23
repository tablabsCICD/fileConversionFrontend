import 'package:file_convertor/features/file_conversion/data/models/conversion_state.dart';
import 'package:file_convertor/features/file_conversion/data/repositories/conversion_sections_list.dart';
import 'package:file_convertor/features/file_conversion/data/services/conversion_engine.dart';
import 'package:file_convertor/features/file_conversion/data/services/file_converter.dart';
import 'package:file_convertor/features/file_conversion/view/file_upload_page.dart';
import 'package:file_convertor/features/file_conversion/widgets/conversion_panel.dart';
import 'package:file_convertor/features/file_conversion/widgets/conversion_section_card.dart';
import 'package:file_convertor/features/home/widgets/file_upload_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/mocks.dart';
import '../support/showcase.dart';

/// Renders [ConversionPanel] in a fixed state with logged callbacks.
Widget _panel(
  BuildContext context,
  ConversionState state, {
  bool engineAvailable = true,
  bool multiple = false,
}) {
  return Showcase(
    maxWidth: 560,
    child: ConversionPanel(
      state: state,
      toolTitle: multiple ? 'Images to PDF' : 'PDF to DOCX',
      targetFormat: multiple ? 'PDF' : 'DOCX',
      acceptedFormats: multiple ? const ['jpg', 'png', 'webp'] : const ['pdf'],
      allowMultiple: multiple,
      engineAvailable: engineAvailable,
      onPick: logAction(context, 'onPick'),
      onRemove: logValue<int>(context, 'onRemove'),
      onConvert: logAction(context, 'onConvert'),
      onRetry: logAction(context, 'onRetry'),
      onReset: logAction(context, 'onReset'),
      onOpen: logAction(context, 'onOpen'),
      onSave: logAction(context, 'onSave'),
    ),
  );
}

final fileConverter = WidgetbookFolder(
  name: 'File Converter',
  isInitiallyExpanded: true,
  children: [
    WidgetbookComponent(
      name: 'Conversion states',
      useCases: [
        WidgetbookUseCase(
          name: '1 · Idle',
          builder: (context) => _panel(context, const ConversionIdle()),
        ),
        WidgetbookUseCase(
          name: '2 · Invalid file',
          builder: (context) => _panel(
            context,
            const ConversionInvalidFile([
              Fixtures.png,
            ], 'This tool needs a .pdf file, not .png.'),
          ),
        ),
        WidgetbookUseCase(
          name: '3 · Ready',
          builder: (context) =>
              _panel(context, const ConversionReady([Fixtures.pdf])),
        ),
        WidgetbookUseCase(
          name: '3b · Ready (several files)',
          builder: (context) => _panel(
            context,
            const ConversionReady(Fixtures.photos),
            multiple: true,
          ),
        ),
        WidgetbookUseCase(
          name: '4 · Converting (progress)',
          builder: (context) => _panel(
            context,
            ConversionInProgress(
              const [Fixtures.pdf],
              progress: context.knobs.double.slider(
                label: 'Progress',
                initialValue: 0.64,
                min: 0,
                max: 1,
              ),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: '5 · Converting (unknown progress)',
          builder: (context) =>
              _panel(context, const ConversionInProgress([Fixtures.pdf])),
        ),
        WidgetbookUseCase(
          name: '6 · Succeeded',
          builder: (context) => _panel(
            context,
            const ConversionSucceeded([Fixtures.pdf], Fixtures.result),
          ),
        ),
        WidgetbookUseCase(
          name: '7 · Failed',
          builder: (context) => _panel(
            context,
            ConversionFailed(
              const [Fixtures.pdf],
              context.knobs.string(
                label: 'Error message',
                initialValue: 'This file is not a valid DOCX document.',
              ),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: '8 · Not available on device',
          builder: (context) =>
              _panel(context, const ConversionIdle(), engineAvailable: false),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Converter screen',
      useCases: [
        WidgetbookUseCase(
          name: 'Interactive (mock engine)',
          builder: (context) {
            final fail = context.knobs.boolean(label: 'Simulate failure');
            final progress = context.knobs.boolean(
              label: 'Engine reports progress',
              initialValue: true,
            );
            final tool = context.knobs.object.dropdown(
              label: 'Tool',
              options: [
                for (final s in conversionSections)
                  ...s.items.where((i) => OnDeviceTools.supports(i.title)),
              ],
              labelBuilder: (i) => i.title,
            );
            return ProviderScope(
              key: ValueKey('$fail-$progress-${tool.title}'),
              overrides: [
                fileConverterProvider.overrideWithValue(
                  DemoFileConverter(fail: fail, reportProgress: progress),
                ),
              ],
              child: FileUploadPage(item: tool),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Real engine',
          builder: (context) => const FileUploadPage(item: Fixtures.pngToJpg),
        ),
        WidgetbookUseCase(
          name: 'Tool not on device',
          builder: (context) => const FileUploadPage(item: Fixtures.pdfToDocx),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Tool section card',
      useCases: [
        WidgetbookUseCase(
          name: 'Card',
          builder: (context) => Showcase(
            maxWidth: 320,
            child: ConversionSectionCard(
              section: context.knobs.object.dropdown(
                label: 'Section',
                options: conversionSections,
                labelBuilder: (s) => s.title,
              ),
              isAvailable: (i) => OnDeviceTools.supports(i.title),
              onSelect: (item) =>
                  logAction(context, 'onSelect(${item.title})')(),
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Quick convert card',
      useCases: [
        WidgetbookUseCase(
          name: 'Full',
          builder: (context) =>
              const Showcase(maxWidth: 600, child: FileUploadCard()),
        ),
        WidgetbookUseCase(
          name: 'Short',
          builder: (context) => const Showcase(
            maxWidth: 220,
            child: FileUploadCard(isShort: true),
          ),
        ),
      ],
    ),
  ],
);
