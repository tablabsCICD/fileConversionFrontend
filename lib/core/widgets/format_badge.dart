import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:flutter/material.dart';

/// Monospaced format tag tinted by its file family: `PDF`, `DOCX`, `MP4`.
class FormatBadge extends StatelessWidget {
  const FormatBadge(this.format, {super.key, this.family, this.large = false});

  /// Extension or format name; shown uppercase.
  final String format;

  /// Overrides the family derived from [format].
  final FileFamily? family;

  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.family(family ?? FileFamily.fromExtension(format));
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 7,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), p.surface),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        format.toUpperCase(),
        style: AppType.mono.copyWith(
          color: color,
          fontSize: large ? 13 : 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          height: 1.1,
        ),
      ),
    );
  }
}

/// `PDF → DOCX`: a source and target format joined by an arrow.
class FormatPair extends StatelessWidget {
  const FormatPair({
    super.key,
    required this.from,
    required this.to,
    this.large = false,
  });

  final String from;
  final String to;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$from to $to',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FormatBadge(from, large: large),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs - 2),
            child: Icon(
              Icons.arrow_forward,
              size: large ? 16 : 13,
              color: context.palette.inkMuted,
            ),
          ),
          FormatBadge(to, large: large),
        ],
      ),
    );
  }
}
