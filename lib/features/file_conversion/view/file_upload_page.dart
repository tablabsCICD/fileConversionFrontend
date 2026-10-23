import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/services/file_actions.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/features/file_conversion/data/helper/conversion_helper.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_state.dart';
import 'package:file_convertor/features/file_conversion/data/services/conversion_engine.dart';
import 'package:file_convertor/features/file_conversion/data/services/file_converter.dart';
import 'package:file_convertor/features/file_conversion/widgets/conversion_panel.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/conversion_section.dart';

class FileUploadPage extends ConsumerStatefulWidget {
  final ConversionItem item;

  /// Files already chosen elsewhere (e.g. Home's quick convert).
  final List<SelectedFile> initialFiles;

  const FileUploadPage({
    super.key,
    required this.item,
    this.initialFiles = const [],
  });

  @override
  ConsumerState<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends ConsumerState<FileUploadPage> {
  late ConversionState _state = widget.initialFiles.isEmpty
      ? const ConversionIdle()
      : _validate(widget.initialFiles);

  late final List<String> allowedExtensions =
      ConversionHelper.allowedExtensionsFromTitle(widget.item.title);

  late final (String, String)? _pair = ConversionHelper.formatPairFromTitle(
    widget.item.title,
  );

  bool get _multiple => OnDeviceTools.of(widget.item.title)?.multiple ?? false;

  /// Converts a picker result into [SelectedFile]s.
  static List<SelectedFile> fromPicker(FilePickerResult result) => [
    for (final f in result.files)
      SelectedFile(
        name: f.name,
        sizeBytes: f.size,
        path: kIsWeb ? null : f.path,
        bytes: kIsWeb ? f.bytes : null,
      ),
  ];

  ConversionState _validate(List<SelectedFile> files) {
    // Some platforms ignore the extension filter, so check again.
    final bad = files.where(
      (f) => !ConversionHelper.isAccepted(f.name, allowedExtensions),
    );
    if (bad.isNotEmpty) {
      final ext = FileFormat.extensionOf(bad.first.name);
      return ConversionInvalidFile(
        files,
        'This tool needs ${_formatList(allowedExtensions)}'
        '${ext == null ? '.' : ', not .$ext.'}',
      );
    }
    return ConversionReady(files);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: _multiple,
      withData: kIsWeb,
      type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    final picked = fromPicker(result);
    final keep = _multiple && _state is ConversionReady
        ? _state.files
        : const <SelectedFile>[];
    setState(() => _state = _validate([...keep, ...picked]));
  }

  void _remove(int index) {
    final files = [..._state.files]..removeAt(index);
    setState(() {
      _state = files.isEmpty ? const ConversionIdle() : _validate(files);
    });
  }

  Future<void> _convert() async {
    final files = _state.files;
    if (files.isEmpty) return;
    final converter = ref.read(fileConverterProvider);

    setState(() => _state = ConversionInProgress(files));
    try {
      final result = await converter.convert(
        toolTitle: widget.item.title,
        files: files,
        onProgress: (value) {
          if (mounted && _state is ConversionInProgress) {
            setState(
              () => _state = ConversionInProgress(files, progress: value),
            );
          }
        },
      );
      if (!mounted) return;
      setState(() => _state = ConversionSucceeded(files, result));
      ref
          .read(activityProvider.notifier)
          .add(
            ActivityEntry.create(
              kind: ActivityKind.converted,
              name: result.fileName,
              sizeBytes: result.sizeBytes,
              path: result.path,
              detail: widget.item.title,
            ),
          );
    } on ConversionException catch (e) {
      if (!mounted) return;
      setState(() => _state = ConversionFailed(files, e.message));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ConversionFailed(
          files,
          'Something went wrong while converting. Check the file and try again.',
        );
      });
    }
  }

  Future<void> _open() async {
    final path = switch (_state) {
      ConversionSucceeded(:final result) => result.path,
      _ => null,
    };
    if (path == null) return;
    final error = await FileActions.open(path);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _save() async {
    final result = switch (_state) {
      ConversionSucceeded(:final result) => result,
      _ => null,
    };
    if (result?.path == null) return;
    try {
      final saved = await FileActions.saveCopyOf(
        result!.path!,
        fileName: result.fileName,
      );
      if (saved != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved ${result.fileName}')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not save a copy.')));
      }
    }
  }

  static String _formatList(List<String> exts) {
    final dotted = exts.map((e) => '.$e').toList();
    if (dotted.length == 1) return 'a ${dotted.first} file';
    return 'a ${dotted.sublist(0, dotted.length - 1).join(', ')} or '
        '${dotted.last} file';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engineAvailable = ref
        .watch(fileConverterProvider)
        .supports(widget.item.title);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final gutter = AppSpace.gutter(width);
    final hasPath = switch (_state) {
      ConversionSucceeded(:final result) => result.path != null,
      _ => false,
    };

    final panel = ConversionPanel(
      state: _state,
      toolTitle: widget.item.title,
      targetFormat: _pair?.$2,
      acceptedFormats: allowedExtensions,
      allowMultiple: _multiple,
      engineAvailable: engineAvailable,
      onPick: _pickFile,
      onRemove: _remove,
      onConvert: _convert,
      onRetry: _convert,
      onReset: () => setState(() => _state = const ConversionIdle()),
      onOpen: hasPath && !kIsWeb ? _open : null,
      onSave: hasPath ? _save : null,
    );

    final hero = _Hero(item: widget.item, pair: _pair, wide: wide);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          /// --------------------------------------------------
          /// Sliver AppBar
          /// --------------------------------------------------
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            leadingWidth: gutter + AppSize.tapTarget,
            leading: Padding(
              padding: EdgeInsets.only(left: gutter - AppSpace.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back to tools',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text(
              'CONVERTER',
              style: AppType.eyebrow.copyWith(color: context.palette.inkMuted),
            ),
            centerTitle: false,
          ),

          /// --------------------------------------------------
          /// Main Content
          /// --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              wide ? AppSpace.xl : AppSpace.xs,
              gutter,
              AppSpace.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 1080 : AppBreakpoints.content,
                  ),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpace.lg,
                                  right: AppSpace.xxl,
                                ),
                                child: hero,
                              ),
                            ),
                            Expanded(flex: 6, child: panel),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            hero,
                            const SizedBox(height: AppSpace.xl - 4),
                            panel,
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editorial title: "PDF *to* DOCX", with the tool's family colour as a rule.
class _Hero extends StatelessWidget {
  const _Hero({required this.item, required this.pair, required this.wide});

  final ConversionItem item;
  final (String, String)? pair;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final family = FileFamily.fromConversionTitle(item.title);
    final style = (wide ? text.displayMedium : text.displaySmall)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 40, height: 3, color: p.family(family)),
        const SizedBox(height: AppSpace.md),
        Semantics(
          header: true,
          label: 'Convert ${item.title}',
          excludeSemantics: true,
          child: Text.rich(
            pair == null
                ? TextSpan(text: item.title)
                : TextSpan(
                    children: [
                      TextSpan(text: pair!.$1),
                      TextSpan(
                        text: ' to ',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: p.inkMuted,
                        ),
                      ),
                      TextSpan(text: pair!.$2),
                    ],
                  ),
            style: style,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          ConversionHelper.subtitleFromTitle(item.title),
          style: text.bodyLarge?.copyWith(color: p.inkMuted),
        ),
      ],
    );
  }
}
