import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/file_glyph.dart';
import 'package:flutter/material.dart';

/// One file, one row: glyph, name, mono metadata, optional trailing action.
class FileTile extends StatelessWidget {
  const FileTile({
    super.key,
    required this.name,
    this.sizeLabel,
    this.caption,
    this.trailing,
    this.onTap,
    this.errorText,
    this.highlighted = false,
    this.dense = false,
  });

  final String name;

  /// Pre-formatted size, e.g. `2.4 MB`.
  final String? sizeLabel;

  /// Extra metadata appended after the size, e.g. `Ready to convert`.
  final String? caption;

  final Widget? trailing;
  final VoidCallback? onTap;

  /// Puts the tile in an error state and explains why.
  final String? errorText;

  /// Accent outline, e.g. for a freshly converted result.
  final bool highlighted;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final ext = FileFormat.extensionOf(name);
    final hasError = errorText != null;

    final meta = [
      if (ext != null) ext.toUpperCase(),
      ?sizeLabel,
      ?caption,
    ].join(' · ');

    final borderColor = hasError
        ? p.danger
        : highlighted
        ? p.accent
        : p.line;

    final body = Padding(
      padding: EdgeInsets.all(dense ? AppSpace.sm : AppSpace.md - 2),
      child: Row(
        children: [
          FileGlyph(extension: ext, size: dense ? 30 : 38),
          const SizedBox(width: AppSpace.md - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.mono.copyWith(
                      color: p.inkMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
                if (hasError) ...[
                  const SizedBox(height: AppSpace.xs - 2),
                  Row(
                    children: [
                      Icon(Icons.error_outline, size: 14, color: p.danger),
                      const SizedBox(width: AppSpace.xxs + 2),
                      Expanded(
                        child: Text(
                          errorText!,
                          style: text.bodySmall?.copyWith(color: p.danger),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.xs),
            trailing!,
          ],
        ],
      ),
    );

    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(
          color: borderColor,
          width: hasError || highlighted ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              hoverColor: p.ink.withValues(alpha: 0.03),
              child: body,
            ),
    );
  }
}
