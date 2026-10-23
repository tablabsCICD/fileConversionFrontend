import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/custom_text_form_field.dart';
import 'package:file_convertor/core/widgets/drop_zone.dart';
import 'package:file_convertor/core/widgets/empty_state.dart';
import 'package:file_convertor/core/widgets/file_glyph.dart';
import 'package:file_convertor/core/widgets/file_tile.dart';
import 'package:file_convertor/core/widgets/format_badge.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/core/widgets/progress_track.dart';
import 'package:file_convertor/core/widgets/section_header.dart';
import 'package:file_convertor/core/widgets/segmented_toggle.dart';
import 'package:file_convertor/core/widgets/toggle_theme_button.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/showcase.dart';

List<String> _formatsKnob(BuildContext context, String initial) => context.knobs
    .string(label: 'Accepted formats (comma separated)', initialValue: initial)
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

final components = WidgetbookFolder(
  name: 'Components',
  children: [
    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Button',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final k = context.knobs;
            return Showcase(
              child: Center(
                child: AppButton(
                  label: k.string(
                    label: 'Label',
                    initialValue: 'Convert to DOCX',
                  ),
                  variant: k.object.dropdown(
                    label: 'Variant',
                    options: AppButtonVariant.values,
                    labelBuilder: (v) => v.name,
                  ),
                  size: k.object.segmented(
                    label: 'Size',
                    options: AppButtonSize.values,
                    initialOption: AppButtonSize.medium,
                    labelBuilder: (v) => v.name,
                  ),
                  icon: k.boolean(label: 'Leading icon')
                      ? Icons.north_east
                      : null,
                  trailingIcon:
                      k.boolean(label: 'Trailing icon', initialValue: true)
                      ? Icons.arrow_forward
                      : null,
                  isLoading: k.boolean(label: 'Loading'),
                  expand: k.boolean(label: 'Expand'),
                  onPressed: k.boolean(label: 'Disabled')
                      ? null
                      : logAction(context, 'onPressed'),
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'All variants',
          builder: (context) => Showcase(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final v in AppButtonVariant.values) ...[
                  Specimen(
                    label: v.name,
                    child: Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final s in AppButtonSize.values)
                          AppButton(
                            label: s.name,
                            variant: v,
                            size: s,
                            onPressed: logAction(
                              context,
                              '${v.name}.${s.name}',
                            ),
                          ),
                        AppButton(
                          label: 'Disabled',
                          variant: v,
                          onPressed: null,
                        ),
                        AppButton(
                          label: 'Loading',
                          variant: v,
                          isLoading: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],
              ],
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Icon button',
          builder: (context) => Showcase(
            child: Wrap(
              spacing: AppSpace.sm,
              children: [
                AppIconButton(
                  icon: Icons.close,
                  tooltip: 'Remove file',
                  onPressed: logAction(context, 'remove'),
                ),
                AppIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  filled: true,
                  onPressed: logAction(context, 'back'),
                ),
                const AppIconButton(
                  icon: Icons.download_rounded,
                  tooltip: 'Download (disabled)',
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Theme toggle',
          builder: (context) =>
              const Showcase(child: Center(child: ToggleThemeButton())),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Text field',
      useCases: [
        WidgetbookUseCase(
          name: 'Search',
          builder: (context) => Showcase(
            child: CustomTextFormField(
              controller: TextEditingController(),
              hintText: context.knobs.string(
                label: 'Hint',
                initialValue: 'Search conversions — try “pdf”',
              ),
              prefix: const Icon(Icons.search),
              onChanged: logValue<String>(context, 'onChanged'),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Labelled form',
          builder: (context) => Showcase(
            child: Column(
              children: [
                CustomTextFormField(
                  controller: TextEditingController(),
                  labelText: 'Sender IP',
                  hintText: '192.168.1.24',
                  prefix: const Icon(Icons.lan_outlined),
                ),
                const SizedBox(height: AppSpace.md),
                CustomTextFormField(
                  controller: TextEditingController(text: '8080'),
                  labelText: 'Port',
                  hintText: '8080',
                  keyboardType: TextInputType.number,
                  prefix: const Icon(Icons.numbers),
                ),
              ],
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Disabled',
          builder: (context) => Showcase(
            child: CustomTextFormField(
              controller: TextEditingController(text: 'Read only value'),
              labelText: 'Disabled',
              hintText: '',
              enabled: false,
            ),
          ),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Format badge',
      useCases: [
        WidgetbookUseCase(
          name: 'Badge',
          builder: (context) => Showcase(
            child: Center(
              child: FormatBadge(
                context.knobs.string(label: 'Format', initialValue: 'pdf'),
                large: context.knobs.boolean(label: 'Large'),
              ),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Format pair',
          builder: (context) => Showcase(
            child: Center(
              child: FormatPair(
                from: context.knobs.string(label: 'From', initialValue: 'PDF'),
                to: context.knobs.string(label: 'To', initialValue: 'DOCX'),
                large: context.knobs.boolean(
                  label: 'Large',
                  initialValue: true,
                ),
              ),
            ),
          ),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'File glyph',
      useCases: [
        WidgetbookUseCase(
          name: 'Glyph',
          builder: (context) => Showcase(
            child: Center(
              child: FileGlyph(
                extension: context.knobs.string(
                  label: 'Extension',
                  initialValue: 'pdf',
                ),
                size: context.knobs.double.slider(
                  label: 'Size',
                  initialValue: 72,
                  min: 24,
                  max: 160,
                ),
              ),
            ),
          ),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'File tile',
      useCases: [
        WidgetbookUseCase(
          name: 'Default',
          builder: (context) => Showcase(
            child: FileTile(
              name: context.knobs.string(
                label: 'File name',
                initialValue: 'Quarterly report — final.pdf',
              ),
              sizeLabel: context.knobs.string(
                label: 'Size',
                initialValue: '2.3 MB',
              ),
              dense: context.knobs.boolean(label: 'Dense'),
              onTap: logAction(context, 'onTap'),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Removable',
          builder: (context) => Showcase(
            child: FileTile(
              name: 'holiday-photo.heic',
              sizeLabel: '4.1 MB',
              caption: 'Ready',
              trailing: AppIconButton(
                icon: Icons.close,
                tooltip: 'Remove file',
                onPressed: logAction(context, 'onRemove'),
              ),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Invalid file',
          builder: (context) => const Showcase(
            child: FileTile(
              name: 'diagram@2x.png',
              sizeLabel: '793 KB',
              errorText: 'This tool needs a .pdf file, not .png.',
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Result (highlighted)',
          builder: (context) => const Showcase(
            child: FileTile(
              name: 'Quarterly report — final.docx',
              sizeLabel: '1.5 MB',
              caption: '38% smaller',
              highlighted: true,
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Very long name',
          builder: (context) => const Showcase(
            maxWidth: 340,
            child: FileTile(
              name:
                  'Annual-Financial-Statements-2026-Consolidated-Draft-v14-FINAL-really-final.xlsx',
              sizeLabel: '12.8 MB',
            ),
          ),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Drop zone',
      useCases: [
        WidgetbookUseCase(
          name: 'Idle',
          builder: (context) {
            final formats = _formatsKnob(context, 'pdf');
            return Showcase(
              child: DropZone(
                title: context.knobs.string(
                  label: 'Title',
                  initialValue: 'Choose a file',
                ),
                caption: describeFormats(formats),
                formats: formats,
                onTap: logAction(context, 'onTap (open picker)'),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Multiple formats',
          builder: (context) {
            final formats = _formatsKnob(context, 'jpg, jpeg, png, webp, heic');
            return Showcase(
              child: DropZone(
                caption: describeFormats(formats),
                formats: formats,
                onTap: logAction(context, 'onTap'),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Invalid file',
          builder: (context) => Showcase(
            child: DropZone(
              formats: const ['pdf'],
              caption: describeFormats(const ['pdf']),
              errorText: 'That file is a .png. Choose a .pdf file.',
              actionLabel: 'Choose another',
              onTap: logAction(context, 'onTap'),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Compact',
          builder: (context) => Showcase(
            maxWidth: 220,
            child: DropZone(
              compact: true,
              title: 'Quick upload',
              caption: 'Any file type',
              actionLabel: 'Select',
              onTap: logAction(context, 'onTap'),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Disabled',
          builder: (context) => const Showcase(
            child: DropZone(onTap: null, caption: 'Picker unavailable'),
          ),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Progress track',
      useCases: [
        WidgetbookUseCase(
          name: 'Determinate',
          builder: (context) => Showcase(
            child: ProgressTrack(
              label: context.knobs.string(
                label: 'Label',
                initialValue: 'Converting to DOCX',
              ),
              value: context.knobs.double.slider(
                label: 'Value',
                initialValue: 0.42,
                min: 0,
                max: 1,
              ),
              detail: context.knobs.boolean(label: 'Show detail')
                  ? '1.0 of 2.3 MB'
                  : null,
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Indeterminate',
          builder: (context) =>
              const Showcase(child: ProgressTrack(label: 'Preparing file')),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Notice',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) => Showcase(
            child: InlineNotice(
              tone: context.knobs.object.segmented(
                label: 'Tone',
                options: NoticeTone.values,
                labelBuilder: (t) => t.name,
              ),
              title: context.knobs.string(
                label: 'Title',
                initialValue: 'Conversion engine not connected',
              ),
              message: context.knobs.string(
                label: 'Message',
                initialValue:
                    'You can choose and check files, but this build cannot '
                    'convert them yet.',
              ),
              action: context.knobs.boolean(label: 'With action')
                  ? AppButton(
                      label: 'Try again',
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.secondary,
                      onPressed: logAction(context, 'action'),
                    )
                  : null,
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'All tones',
          builder: (context) => const Showcase(
            child: Column(
              children: [
                InlineNotice(title: 'Receiving file…'),
                SizedBox(height: AppSpace.sm),
                InlineNotice(
                  tone: NoticeTone.success,
                  title: 'File received successfully',
                ),
                SizedBox(height: AppSpace.sm),
                InlineNotice(
                  tone: NoticeTone.warning,
                  title: "Enter the sender's IP address and port number.",
                ),
                SizedBox(height: AppSpace.sm),
                InlineNotice(
                  tone: NoticeTone.danger,
                  title: 'Conversion failed',
                  message: 'The file appears to be password-protected.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Segmented toggle',
      useCases: [
        WidgetbookUseCase(
          name: 'Interactive',
          builder: (context) {
            var index = 0;
            return Showcase(
              child: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => SegmentedToggle(
                    segments: const ['Convert', 'Storage'],
                    selectedIndex: index,
                    onChanged: (i) {
                      setState(() => index = i);
                      logValue<int>(context, 'onChanged')(i);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Section header',
      useCases: [
        WidgetbookUseCase(
          name: 'Header',
          builder: (context) => Showcase(
            child: SectionHeader(
              eyebrow: context.knobs.string(
                label: 'Eyebrow',
                initialValue: 'Recent',
              ),
              index: context.knobs.intOrNull.slider(
                label: 'Index',
                initialValue: 2,
                min: 1,
                max: 9,
              ),
              title: context.knobs.string(
                label: 'Title',
                initialValue: 'Recent files',
              ),
              large: context.knobs.boolean(label: 'Large (serif)'),
              trailing: AppButton(
                label: 'View all',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                trailingIcon: Icons.arrow_forward,
                onPressed: logAction(context, 'viewAll'),
              ),
            ),
          ),
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    WidgetbookComponent(
      name: 'Empty state',
      useCases: [
        WidgetbookUseCase(
          name: 'No results',
          builder: (context) => Showcase(
            child: EmptyState(
              title: context.knobs.string(
                label: 'Title',
                initialValue: 'No matching tools',
              ),
              message: context.knobs.string(
                label: 'Message',
                initialValue:
                    'Nothing matches “pptx”. Try a file extension such as PDF, '
                    'PNG or MP4.',
              ),
              action: AppButton(
                label: 'Clear search',
                variant: AppButtonVariant.secondary,
                onPressed: logAction(context, 'clearSearch'),
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);
