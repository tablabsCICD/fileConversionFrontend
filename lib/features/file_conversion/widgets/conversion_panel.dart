import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/drop_zone.dart';
import 'package:file_convertor/core/widgets/file_tile.dart';
import 'package:file_convertor/core/widgets/format_badge.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/core/widgets/progress_track.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_state.dart';
import 'package:flutter/material.dart';

/// The converter workspace card. Stateless: renders [state] and reports
/// intents through callbacks, so every state can be previewed in isolation.
class ConversionPanel extends StatelessWidget {
  const ConversionPanel({
    super.key,
    required this.state,
    required this.toolTitle,
    this.targetFormat,
    this.acceptedFormats = const [],
    this.allowMultiple = false,
    this.engineAvailable = true,
    this.onPick,
    this.onRemove,
    this.onConvert,
    this.onRetry,
    this.onReset,
    this.onOpen,
    this.onSave,
  });

  final ConversionState state;

  /// e.g. "PDF to DOCX" or "Compress Images".
  final String toolTitle;

  /// e.g. "DOCX". Null for tools without a single output format.
  final String? targetFormat;

  final List<String> acceptedFormats;

  /// The tool combines several files (e.g. Images to PDF).
  final bool allowMultiple;

  /// False when this tool cannot run on this device.
  final bool engineAvailable;

  /// Picks (more) files.
  final VoidCallback? onPick;

  /// Removes the file at the given index.
  final ValueChanged<int>? onRemove;
  final VoidCallback? onConvert;
  final VoidCallback? onRetry;
  final VoidCallback? onReset;

  /// Opens the converted file. Hidden when null.
  final VoidCallback? onOpen;

  /// Saves a copy of the converted file elsewhere. Hidden when null.
  final VoidCallback? onSave;

  String get _outputLabel => targetFormat ?? toolTitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.sheet,
        border: Border.all(color: p.line),
      ),
      padding: const EdgeInsets.all(AppSpace.lg - 4),
      child: AnimatedSize(
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.emphasized,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.base),
          switchInCurve: AppMotion.emphasized,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: KeyedSubtree(
            key: ValueKey(state.runtimeType),
            child: switch (state) {
              ConversionSucceeded s => _success(context, s),
              _ => _workspace(context),
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SOURCE + OUTPUT (idle, invalid, ready, converting, failed)
  // ---------------------------------------------------------------------------
  Widget _workspace(BuildContext context) {
    final p = context.palette;
    final s = state;
    final converting = s is ConversionInProgress;
    final files = s.files;

    final Widget source;
    if (s is ConversionIdle) {
      source = DropZone(
        onTap: engineAvailable ? onPick : null,
        title: allowMultiple ? 'Choose files' : 'Choose a file',
        caption: describeFormats(acceptedFormats),
        formats: acceptedFormats,
        actionLabel: 'Browse files',
      );
    } else {
      final total = files.fold<int>(0, (n, f) => n + f.sizeBytes);
      source = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < files.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.xs),
            FileTile(
              name: files[i].name,
              sizeLabel: FileFormat.formatBytes(files[i].sizeBytes),
              caption: s is ConversionInvalidFile
                  ? null
                  : converting
                  ? 'Converting'
                  : 'Ready',
              errorText: s is ConversionInvalidFile && i == files.length - 1
                  ? s.message
                  : null,
              dense: files.length > 2,
              trailing: converting
                  ? null
                  : AppIconButton(
                      icon: Icons.close,
                      tooltip: 'Remove ${files[i].name}',
                      onPressed: onRemove == null ? null : () => onRemove!(i),
                    ),
            ),
          ],
          if (!converting && (allowMultiple || s is ConversionInvalidFile)) ...[
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                AppButton(
                  label: s is ConversionInvalidFile
                      ? 'Choose a different file'
                      : 'Add more',
                  icon: s is ConversionInvalidFile
                      ? Icons.swap_horiz
                      : Icons.add,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  onPressed: onPick,
                ),
                const Spacer(),
                if (files.length > 1)
                  Text(
                    '${files.length} FILES · ${FileFormat.formatBytes(total)}',
                    style: AppType.eyebrow.copyWith(color: p.inkMuted),
                  ),
              ],
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepLabel(index: 1, label: allowMultiple ? 'Sources' : 'Source'),
        const SizedBox(height: AppSpace.sm),
        source,
        const SizedBox(height: AppSpace.lg),
        Divider(color: p.line),
        const SizedBox(height: AppSpace.lg - 4),
        Row(
          children: [
            Expanded(child: _StepLabel(index: 2, label: 'Output')),
            if (targetFormat != null)
              FormatBadge(targetFormat!, large: true)
            else
              Flexible(
                child: Text(
                  toolTitle,
                  textAlign: TextAlign.end,
                  style: AppType.mono.copyWith(color: p.ink),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        ..._actions(context),
      ],
    );
  }

  List<Widget> _actions(BuildContext context) {
    final s = state;

    if (s is ConversionInProgress) {
      return [
        ProgressTrack(label: 'Converting to $_outputLabel', value: s.progress),
        const SizedBox(height: AppSpace.md),
        const AppButton(
          label: 'Converting…',
          onPressed: null,
          isLoading: true,
          size: AppButtonSize.large,
          expand: true,
        ),
      ];
    }

    if (s is ConversionFailed) {
      return [
        InlineNotice(
          tone: NoticeTone.danger,
          title: 'Conversion failed',
          message: s.message,
        ),
        const SizedBox(height: AppSpace.md),
        AppButton(
          label: 'Try again',
          icon: Icons.refresh,
          onPressed: onRetry,
          size: AppButtonSize.large,
          expand: true,
        ),
      ];
    }

    final ready = s is ConversionReady;
    return [
      if (!engineAvailable) ...[
        const InlineNotice(
          tone: NoticeTone.warning,
          title: 'Not available on this device yet',
          message:
              'This conversion needs a server or native codecs that this '
              'version of the app does not include.',
        ),
        const SizedBox(height: AppSpace.md),
      ],
      AppButton(
        label: 'Convert to $_outputLabel',
        trailingIcon: Icons.arrow_forward,
        onPressed: ready && engineAvailable ? onConvert : null,
        size: AppButtonSize.large,
        expand: true,
      ),
      if (s is ConversionIdle && engineAvailable) ...[
        const SizedBox(height: AppSpace.sm),
        Text(
          allowMultiple
              ? 'Choose one or more files to continue'
              : 'Choose a file to continue',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ];
  }

  // ---------------------------------------------------------------------------
  // SUCCESS
  // ---------------------------------------------------------------------------
  Widget _success(BuildContext context, ConversionSucceeded s) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final sourceLabel = s.files.length == 1
        ? s.files.first.name
        : '${s.files.length} files';
    final sourceBytes = s.files.fold<int>(0, (n, f) => n + f.sizeBytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              _SuccessSeal(color: p.success),
              const SizedBox(width: AppSpace.md - 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Converted.', style: text.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '$sourceLabel → $_outputLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.mono.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg - 4),
        FileTile(
          name: s.result.fileName,
          sizeLabel: FileFormat.formatBytes(s.result.sizeBytes),
          caption: _sizeDelta(sourceBytes, s.result.sizeBytes),
          highlighted: true,
          onTap: onOpen,
        ),
        const SizedBox(height: AppSpace.lg - 4),
        if (onOpen != null) ...[
          AppButton(
            label: 'Open',
            icon: Icons.open_in_new,
            onPressed: onOpen,
            size: AppButtonSize.large,
            expand: true,
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Row(
          children: [
            if (onSave != null) ...[
              Expanded(
                child: AppButton(
                  label: 'Save a copy',
                  icon: Icons.download_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: onSave,
                  expand: true,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
            ],
            Expanded(
              child: AppButton(
                label: 'Convert another',
                icon: Icons.add,
                variant: AppButtonVariant.secondary,
                onPressed: onReset,
                expand: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String? _sizeDelta(int before, int after) {
    if (before <= 0) return null;
    final change = ((after - before) / before * 100).round();
    if (change == 0) return 'same size';
    return change < 0 ? '${-change}% smaller' : '$change% larger';
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${index.toString().padLeft(2, '0')} — ${label.toUpperCase()}',
      style: AppType.eyebrow.copyWith(color: context.palette.inkMuted),
    );
  }
}

/// A check mark that draws itself in once.
class _SuccessSeal extends StatelessWidget {
  const _SuccessSeal({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.emphasized,
      builder: (context, t, _) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.alphaBlend(
            color.withValues(alpha: 0.14),
            context.palette.surface,
          ),
        ),
        child: CustomPaint(
          painter: _CheckPainter(color: color, t: t),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.71, size.height * 0.38);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.color != color;
}
