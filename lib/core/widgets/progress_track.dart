import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Labelled progress bar.
///
/// Pass a [value] (0–1) only when real progress is known; with `null` the
/// track shows an indeterminate sweep and no percentage, so it never implies
/// precision it does not have.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.label,
    this.value,
    this.detail,
    this.color,
  });

  final String label;
  final double? value;

  /// Right-aligned secondary text, e.g. `3.2 of 8 MB`.
  final String? detail;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value?.clamp(0.0, 1.0);
    final percent = v == null ? null : '${(v * 100).round()}%';

    return Semantics(
      label: label,
      value: percent ?? 'In progress',
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              if (detail != null || percent != null)
                Text(
                  [?detail, ?percent].join(' · '),
                  style: AppType.mono.copyWith(color: p.inkMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: v == null
                ? LinearProgressIndicator(
                    minHeight: 6,
                    color: color ?? p.accent,
                    backgroundColor: p.surfaceSunken,
                  )
                : TweenAnimationBuilder<double>(
                    tween: Tween(end: v),
                    duration: AppMotion.of(context, AppMotion.base),
                    curve: AppMotion.standard,
                    builder: (context, animated, _) => LinearProgressIndicator(
                      value: animated,
                      minHeight: 6,
                      color: color ?? p.accent,
                      backgroundColor: p.surfaceSunken,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
