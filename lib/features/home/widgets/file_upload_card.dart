import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/drop_zone.dart';
import 'package:file_convertor/core/widgets/file_tile.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/features/file_conversion/data/helper/conversion_helper.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_section.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_state.dart';
import 'package:file_convertor/features/file_conversion/data/repositories/conversion_sections_list.dart';
import 'package:file_convertor/features/file_conversion/data/services/file_converter.dart';
import 'package:file_convertor/features/file_conversion/view/file_upload_page.dart';
import 'package:file_convertor/features/file_conversion/widgets/conversion_section_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick convert: pick any file, see which on-device tools accept it, and
/// jump straight into the converter with the file already loaded.
class FileUploadCard extends ConsumerStatefulWidget {
  final bool isShort;

  const FileUploadCard({super.key, this.isShort = false});

  /// On-device tools that accept a file named [fileName].
  static List<ConversionItem> toolsFor(
    String fileName,
    bool Function(String title) supports,
  ) {
    final specific = <ConversionItem>[];
    final generic = <ConversionItem>[];
    for (final section in conversionSections) {
      for (final item in section.items) {
        if (!supports(item.title)) continue;
        final exts = ConversionHelper.allowedExtensionsFromTitle(item.title);
        if (exts.isEmpty) {
          generic.add(item);
        } else if (ConversionHelper.isAccepted(fileName, exts)) {
          if (!specific.any((i) => i.title == item.title)) specific.add(item);
        }
      }
    }
    return [...specific, ...generic];
  }

  @override
  ConsumerState<FileUploadCard> createState() => _FileUploadCardState();
}

class _FileUploadCardState extends ConsumerState<FileUploadCard> {
  /// Set when the picked file has no on-device conversion.
  SelectedFile? _unsupported;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.first;
    final file = SelectedFile(
      name: f.name,
      sizeBytes: f.size,
      path: kIsWeb ? null : f.path,
      bytes: kIsWeb ? f.bytes : null,
    );

    final converter = ref.read(fileConverterProvider);
    final tools = FileUploadCard.toolsFor(file.name, converter.supports)
        // "Compress Files" works for anything; it is not a conversion.
        .where((t) => t.title != 'Compress Files')
        .toList();
    if (tools.isEmpty) {
      setState(() => _unsupported = file);
      return;
    }
    setState(() => _unsupported = null);
    final tool = tools.length == 1
        ? tools.first
        : await _chooseTool(file, tools);
    if (tool == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileUploadPage(item: tool, initialFiles: [file]),
      ),
    );
  }

  Future<ConversionItem?> _chooseTool(
    SelectedFile file,
    List<ConversionItem> tools,
  ) {
    return showModalBottomSheet<ConversionItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.palette.surface,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg - 4,
              0,
              AppSpace.lg - 4,
              AppSpace.lg,
            ),
            children: [
              Text(
                'CONVERT TO',
                style: AppType.eyebrow.copyWith(
                  color: context.palette.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              FileTile(
                name: file.name,
                sizeLabel: FileFormat.formatBytes(file.sizeBytes),
                dense: true,
              ),
              const SizedBox(height: AppSpace.sm),
              for (final tool in tools)
                ConversionToolRow(
                  item: tool,
                  onTap: () => Navigator.pop(context, tool),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _unsupportedNotice() {
    final f = _unsupported;
    if (f == null) return null;
    final ext = FileFormat.extensionOf(f.name);
    return InlineNotice(
      tone: NoticeTone.warning,
      title: ext == null
          ? 'No conversions for this file yet'
          : 'No on-device conversions for .$ext yet',
      message: 'Try a document, image, data or text file.',
      action: AppButton(
        label: 'Choose another file',
        size: AppButtonSize.small,
        variant: AppButtonVariant.secondary,
        onPressed: _pickFile,
      ),
    );
  }

  /// ================= SHORT CARD =================
  Widget _shortCard(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropZone(
          compact: true,
          onTap: _pickFile,
          title: 'Quick convert',
          caption: 'Pick any file',
          actionLabel: 'Select',
        ),
        if (_unsupportedNotice() case final notice?) ...[
          const SizedBox(height: AppSpace.sm),
          notice,
        ],
      ],
    );
  }

  /// ================= FULL CARD =================
  Widget _fullCard(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropZone(
                onTap: _pickFile,
                title: 'Choose a file to convert',
                caption: 'Documents · Images · Data · Text · Archives',
                actionLabel: 'Select file',
              ),
              if (_unsupportedNotice() case final notice?) ...[
                const SizedBox(height: AppSpace.sm),
                notice,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return widget.isShort ? _shortCard(context) : _fullCard(context);
  }
}
