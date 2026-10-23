import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_section.dart';
import 'package:flutter/material.dart';

/// A bento card listing the tools in one [ConversionSection].
class ConversionSectionCard extends StatelessWidget {
  final ConversionSection section;
  final ValueChanged<ConversionItem> onSelect;

  /// Whether a tool can run now; unavailable tools are shown as "soon".
  final bool Function(ConversionItem item) isAvailable;

  const ConversionSectionCard({
    super.key,
    required this.section,
    required this.onSelect,
    this.isAvailable = _always,
  });

  static bool _always(ConversionItem _) => true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final family = FileFamily.fromConversionTitle(section.title);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md + 2,
        AppSpace.xs + 2,
        AppSpace.xs + 2,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Section title
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpace.xs),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.family(family),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      section.title,
                      style: AppType.eyebrow.copyWith(color: p.ink),
                    ),
                  ),
                  Text(
                    section.items.length.toString().padLeft(2, '0'),
                    style: AppType.eyebrow.copyWith(color: p.inkMuted),
                    semanticsLabel: '${section.items.length} tools',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpace.sm),

          /// Tools
          for (final item in section.items)
            ConversionToolRow(
              item: item,
              onTap: () => onSelect(item),
              available: isAvailable(item),
            ),
        ],
      ),
    );
  }
}

class ConversionToolRow extends StatefulWidget {
  final ConversionItem item;
  final VoidCallback onTap;

  /// When false the row is muted, tagged "Soon" and not tappable.
  final bool available;

  const ConversionToolRow({
    super.key,
    required this.item,
    required this.onTap,
    this.available = true,
  });

  @override
  State<ConversionToolRow> createState() => _ConversionToolRowState();
}

class _ConversionToolRowState extends State<ConversionToolRow> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final item = widget.item;
    final parts = item.title.split(' to ');
    final target = FileFamily.fromConversionTitle(
      parts.length == 2 ? parts.last : item.title,
    );
    final available = widget.available;
    final color = available ? p.family(target) : p.inkMuted;
    final duration = AppMotion.of(context, AppMotion.fast);

    return Semantics(
      button: true,
      enabled: available,
      label: available ? item.title : '${item.title}, coming soon',
      excludeSemantics: true,
      onTap: available ? widget.onTap : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: available ? widget.onTap : null,
          onHover: (v) => setState(() => _active = v),
          onFocusChange: (v) => setState(() => _active = v),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          hoverColor: p.ink.withValues(alpha: 0.04),
          focusColor: p.accent.withValues(alpha: 0.12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpace.xxs,
                horizontal: AppSpace.xxs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        color.withValues(alpha: 0.12),
                        p.surface,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                    ),
                    child: Icon(item.icon, size: 16, color: color),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: available ? p.ink : p.inkMuted,
                      ),
                    ),
                  ),
                  if (!available)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.line),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'SOON',
                        style: AppType.eyebrow.copyWith(
                          color: p.inkMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    )
                  else
                    AnimatedSlide(
                      duration: duration,
                      offset: Offset(_active ? 0 : -0.3, 0),
                      child: AnimatedOpacity(
                        duration: duration,
                        opacity: _active ? 1 : 0.35,
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: _active ? p.accent : p.inkMuted,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpace.xxs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
