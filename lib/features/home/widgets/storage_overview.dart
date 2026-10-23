import 'dart:math' as math;

import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/services/device_storage_service.dart';
import 'package:file_convertor/core/services/permissions_service.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:flutter/material.dart';

/// One slice of the storage breakdown.
class StorageSlice {
  final String label;
  final int bytes;
  final int? count;
  final Color color;

  const StorageSlice({
    required this.label,
    required this.bytes,
    required this.color,
    this.count,
  });
}

/// Real device storage: capacity ring, stacked breakdown and this app's
/// footprint. Presentational — feed it a [StorageSnapshot].
class StorageOverview extends StatelessWidget {
  const StorageOverview({
    super.key,
    required this.snapshot,
    this.onRequestAccess,
    this.onOpenSettings,
    this.onRefresh,
  });

  final StorageSnapshot snapshot;
  final VoidCallback? onRequestAccess;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final capacity = snapshot.capacity;
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    final slices = _slices(context);
    final children = <Widget>[];

    if (capacity == null) {
      children.add(
        const InlineNotice(
          title: 'Device storage is not available here',
          message: 'This platform does not report disk capacity.',
        ),
      );
    } else {
      final ring = _CapacityRing(capacity: capacity);
      final legend = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Figure(
            label: 'Used',
            value: FileFormat.formatBytes(capacity.usedBytes),
            color: p.accent,
          ),
          const SizedBox(height: AppSpace.sm),
          _Figure(
            label: 'Free',
            value: FileFormat.formatBytes(capacity.freeBytes),
            color: p.surfaceSunken,
            outlined: true,
          ),
          const SizedBox(height: AppSpace.sm),
          _Figure(
            label: 'Total',
            value: FileFormat.formatBytes(capacity.totalBytes),
          ),
        ],
      );
      children.add(
        wide
            ? Row(
                children: [
                  ring,
                  const SizedBox(width: AppSpace.xl),
                  Expanded(child: legend),
                ],
              )
            : Column(
                children: [
                  ring,
                  const SizedBox(height: AppSpace.lg - 4),
                  legend,
                ],
              ),
      );

      children.addAll([
        const SizedBox(height: AppSpace.lg),
        Divider(color: p.line),
        const SizedBox(height: AppSpace.md),
        _eyebrow(context, 'What is using space'),
        const SizedBox(height: AppSpace.sm),
        _StackedBar(slices: slices, total: capacity.totalBytes),
        const SizedBox(height: AppSpace.md),
        _SliceGrid(slices: slices),
      ]);
    }

    final access = _accessNotice();
    if (access != null) {
      children.addAll([const SizedBox(height: AppSpace.md), access]);
    }

    children.addAll([
      const SizedBox(height: AppSpace.lg),
      Divider(color: p.line),
      const SizedBox(height: AppSpace.md),
      _eyebrow(context, 'This app'),
      const SizedBox(height: AppSpace.sm),
      _AppRow(
        icon: Icons.swap_horiz,
        label: 'Converted files',
        bytes: snapshot.app.converted,
      ),
      _AppRow(
        icon: Icons.south_west,
        label: 'Received files',
        bytes: snapshot.app.received,
      ),
      _AppRow(
        icon: Icons.lock_outline,
        label: 'Private Vault',
        bytes: snapshot.app.vault,
      ),
      const SizedBox(height: AppSpace.sm),
      Row(
        children: [
          Expanded(
            child: Text(
              'UPDATED ${_time(snapshot.takenAt)}',
              style: AppType.eyebrow.copyWith(color: p.inkMuted),
            ),
          ),
          if (onRefresh != null)
            AppButton(
              label: 'Refresh',
              icon: Icons.refresh,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.small,
              onPressed: onRefresh,
            ),
        ],
      ),
    ]);

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg - 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.sheet,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  List<StorageSlice> _slices(BuildContext context) {
    final p = context.palette;
    final media = snapshot.media;
    final capacity = snapshot.capacity;
    final slices = <StorageSlice>[
      if (media != null) ...[
        StorageSlice(
          label: 'Images',
          bytes: media.images.bytes,
          count: media.images.count,
          color: p.families[3],
        ),
        StorageSlice(
          label: 'Videos',
          bytes: media.videos.bytes,
          count: media.videos.count,
          color: p.families[4],
        ),
        StorageSlice(
          label: 'Audio',
          bytes: media.audio.bytes,
          count: media.audio.count,
          color: p.families[5],
        ),
      ],
      StorageSlice(
        label: 'This app',
        bytes: snapshot.app.total,
        color: p.accent,
      ),
    ];
    if (capacity != null) {
      final known = slices.fold<int>(0, (n, s) => n + s.bytes);
      slices.add(
        StorageSlice(
          label: media == null ? 'Everything else' : 'System & other apps',
          bytes: math.max(0, capacity.usedBytes - known),
          color: p.inkFaint,
        ),
      );
    }
    return slices;
  }

  Widget? _accessNotice() {
    switch (snapshot.access) {
      case MediaAccess.full:
        return null;
      case MediaAccess.notApplicable:
        return const InlineNotice(
          title: 'Other apps’ files are private on this device',
          message:
              'The system does not let apps measure each other’s files, so '
              'device totals and this app’s files are shown.',
        );
      case MediaAccess.limited:
        return InlineNotice(
          tone: NoticeTone.warning,
          title: 'Showing only the media you selected',
          message: 'Allow access to all photos and videos for a full picture.',
          action: onOpenSettings == null
              ? null
              : AppButton(
                  label: 'Open settings',
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.secondary,
                  onPressed: onOpenSettings,
                ),
        );
      case MediaAccess.denied:
        return InlineNotice(
          tone: NoticeTone.warning,
          title: 'Allow media access to see the breakdown',
          message:
              'Storage permission lets the app measure your photos, videos '
              'and music. Nothing leaves your device.',
          action: onRequestAccess == null
              ? null
              : AppButton(
                  label: 'Allow access',
                  size: AppButtonSize.small,
                  onPressed: onRequestAccess,
                ),
        );
      case MediaAccess.permanentlyDenied:
        return InlineNotice(
          tone: NoticeTone.warning,
          title: 'Media access is turned off',
          message: 'Turn on Photos, Videos and Music access in Settings.',
          action: onOpenSettings == null
              ? null
              : AppButton(
                  label: 'Open settings',
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.secondary,
                  onPressed: onOpenSettings,
                ),
        );
    }
  }

  static Widget _eyebrow(BuildContext context, String text) => Text(
    text.toUpperCase(),
    style: AppType.eyebrow.copyWith(color: context.palette.inkMuted),
  );

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _CapacityRing extends StatelessWidget {
  const _CapacityRing({required this.capacity});

  final StorageCapacity capacity;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fraction = capacity.usedFraction;
    final percent = (fraction * 100).round();
    final tone = fraction >= 0.9 ? p.danger : p.accent;

    return Semantics(
      label: 'Storage used',
      value:
          '$percent percent. ${FileFormat.formatBytes(capacity.freeBytes)} free '
          'of ${FileFormat.formatBytes(capacity.totalBytes)}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 168,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: AppMotion.of(context, AppMotion.slow * 2),
          curve: AppMotion.emphasized,
          builder: (context, value, child) => CustomPaint(
            painter: _RingPainter(
              value: value,
              track: p.surfaceSunken,
              fill: tone,
            ),
            child: child,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: AppType.numeral.copyWith(color: p.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'OF ${FileFormat.formatBytes(capacity.totalBytes)}',
                  style: AppType.eyebrow.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.color,
    this.outlined = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            shape: BoxShape.circle,
            border: outlined || color == null
                ? Border.all(color: p.lineStrong)
                : null,
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        SizedBox(
          width: 56,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: AppType.mono.copyWith(color: p.ink, fontSize: 13)),
      ],
    );
  }
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.slices, required this.total});

  final List<StorageSlice> slices;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, c) {
              var remaining = c.maxWidth;
              final bars = <Widget>[];
              for (final s in slices) {
                if (s.bytes <= 0 || total <= 0) continue;
                final w = math.min(
                  remaining,
                  math.max(2.0, c.maxWidth * s.bytes / total),
                );
                remaining -= w;
                bars.add(Container(width: w, color: s.color));
              }
              return Row(
                children: [
                  ...bars,
                  Expanded(child: ColoredBox(color: p.surfaceSunken)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SliceGrid extends StatelessWidget {
  const _SliceGrid({required this.slices});

  final List<StorageSlice> slices;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 560 ? 3 : 2;
        const gap = AppSpace.sm;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in slices)
              SizedBox(
                width: w,
                child: Semantics(
                  label:
                      '${s.label}: ${FileFormat.formatBytes(s.bytes)}'
                      '${s.count == null ? '' : ', ${s.count} items'}',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.sm),
                    decoration: BoxDecoration(
                      color: p.paper,
                      borderRadius: AppRadius.control,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 30,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                [
                                  FileFormat.formatBytes(s.bytes),
                                  if (s.count != null) '${s.count} items',
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.mono.copyWith(
                                  color: p.inkMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.icon, required this.label, required this.bytes});

  final IconData icon;
  final String label;
  final int bytes;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs - 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.inkMuted),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            FileFormat.formatBytes(bytes),
            style: AppType.mono.copyWith(color: p.ink),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.fill});

  final double value;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value.clamp(0.0, 1.0),
        false,
        base..color = fill,
      );
    }

    // Hairline tick marks every 2.5% — a quiet, instrument-like detail.
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final tick = Paint()
      ..color = track
      ..strokeWidth = 1;
    for (var i = 0; i < 40; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 40;
      final inner = r - stroke - (i % 4 == 0 ? 8 : 5);
      final outer = r - stroke - 3;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * inner,
        c + Offset(math.cos(a), math.sin(a)) * outer,
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.fill != fill;
}
