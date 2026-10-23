import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Mono eyebrow (`02 — RECENT`) over a heading, with an optional trailing
/// action aligned to the heading's baseline.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.index,
    this.trailing,
    this.large = false,
  });

  final String title;
  final String? eyebrow;

  /// Rendered as a zero-padded counter before the eyebrow: `02 —`.
  final int? index;

  final Widget? trailing;

  /// Serif display heading instead of the sans title.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final eyebrowText = [
      if (index != null) index.toString().padLeft(2, '0'),
      if (eyebrow != null) eyebrow!.toUpperCase(),
    ].join(' — ');

    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrowText.isNotEmpty) ...[
                  Text(
                    eyebrowText,
                    style: AppType.eyebrow.copyWith(color: p.inkMuted),
                  ),
                  const SizedBox(height: AppSpace.xs - 2),
                ],
                Text(
                  title,
                  style: large ? text.headlineMedium : text.titleLarge,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
