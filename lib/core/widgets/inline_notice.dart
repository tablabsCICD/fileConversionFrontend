import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum NoticeTone { info, success, warning, danger }

/// Inline status message: icon, title, optional body and action.
///
/// Announced to assistive technology when it appears.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.title,
    this.message,
    this.tone = NoticeTone.info,
    this.action,
  });

  final String title;
  final String? message;
  final NoticeTone tone;

  /// Usually a small [AppButton].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final (Color fg, Color bg, IconData icon) = switch (tone) {
      NoticeTone.info => (p.accent, p.accentSoft, Icons.info_outline),
      NoticeTone.success => (
        p.success,
        p.successSoft,
        Icons.check_circle_outline,
      ),
      NoticeTone.warning => (
        p.warning,
        p.warningSoft,
        Icons.report_gmailerrorred,
      ),
      NoticeTone.danger => (p.danger, p.dangerSoft, Icons.error_outline),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md - 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.control,
          border: Border.all(color: fg.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 19, color: fg),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall?.copyWith(color: fg)),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      message!,
                      style: text.bodySmall?.copyWith(color: p.ink),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
