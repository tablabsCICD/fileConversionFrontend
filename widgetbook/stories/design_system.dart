import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/file_glyph.dart';
import 'package:file_convertor/core/widgets/format_badge.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/showcase.dart';

final designSystem = WidgetbookFolder(
  name: 'Design System',
  isInitiallyExpanded: true,
  children: [
    WidgetbookComponent(
      name: 'Colors',
      useCases: [
        WidgetbookUseCase(
          name: 'Palette',
          builder: (context) => const _ColorsPage(),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'File families',
      useCases: [
        WidgetbookUseCase(
          name: 'Families',
          builder: (context) => const _FamiliesPage(),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Typography',
      useCases: [
        WidgetbookUseCase(
          name: 'Type scale',
          builder: (context) => const _TypographyPage(),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Spacing & Radii',
      useCases: [
        WidgetbookUseCase(
          name: 'Scale',
          builder: (context) => const _SpacingPage(),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Motion',
      useCases: [
        WidgetbookUseCase(
          name: 'Durations & curves',
          builder: (context) => const _MotionPage(),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Iconography',
      useCases: [
        WidgetbookUseCase(
          name: 'Glyphs & icons',
          builder: (context) => const _IconsPage(),
        ),
      ],
    ),
  ],
);

// -----------------------------------------------------------------------------

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class _ColorsPage extends StatelessWidget {
  const _ColorsPage();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final groups = <String, List<(String, Color, Color?)>>{
      'Surfaces': [
        ('paper', p.paper, null),
        ('surface', p.surface, null),
        ('surfaceSunken', p.surfaceSunken, null),
        ('line', p.line, null),
        ('lineStrong', p.lineStrong, p.surface),
      ],
      'Ink': [
        ('ink', p.ink, p.paper),
        ('inkMuted', p.inkMuted, p.paper),
        ('inkFaint', p.inkFaint, p.paper),
      ],
      'Accent': [
        ('accent', p.accent, p.paper),
        ('onAccent', p.onAccent, p.accent),
        ('accentSoft', p.accentSoft, null),
      ],
      'Status': [
        ('success', p.success, p.successSoft),
        ('warning', p.warning, p.warningSoft),
        ('danger', p.danger, p.dangerSoft),
      ],
    };

    return Showcase(
      maxWidth: 880,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Colour', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Studio paper: warm neutrals, ink text, one cobalt accent. '
            'Ratios are WCAG contrast against the pairing shown.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          for (final entry in groups.entries) ...[
            const SizedBox(height: AppSpace.xl),
            Specimen(
              label: entry.key,
              child: Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final (name, color, against) in entry.value)
                    _Swatch(name: name, color: color, against: against),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color, this.against});

  final String name;
  final Color color;
  final Color? against;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = against == null ? null : _contrast(color, against!);
    return Container(
      width: 156,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.control,
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            color: against ?? color,
            alignment: Alignment.center,
            child: against == null
                ? null
                : Text(
                    'Aa',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: color),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.sm - 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  _hex(color),
                  style: AppType.mono.copyWith(color: p.inkMuted),
                ),
                if (ratio != null)
                  Text(
                    '${ratio.toStringAsFixed(2)} : 1',
                    style: AppType.mono.copyWith(
                      color: ratio >= 4.5 ? p.success : p.warning,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamiliesPage extends StatelessWidget {
  const _FamiliesPage();

  static const _examples = {
    FileFamily.pdf: 'pdf',
    FileFamily.document: 'docx',
    FileFamily.data: 'csv',
    FileFamily.image: 'png',
    FileFamily.video: 'mp4',
    FileFamily.audio: 'mp3',
    FileFamily.archive: 'zip',
    FileFamily.other: 'bin',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Showcase(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File families',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Every format maps to one family. The family colour is used only '
            'in small doses: glyphs, badges and markers.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.lg),
          for (final family in FileFamily.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                children: [
                  FileGlyph(extension: _examples[family], size: 40),
                  const SizedBox(width: AppSpace.md),
                  SizedBox(
                    width: 120,
                    child: Text(
                      family.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  FormatBadge(_examples[family]!, family: family),
                  const Spacer(),
                  Text(
                    _hex(p.family(family)),
                    style: AppType.mono.copyWith(color: p.inkMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TypographyPage extends StatelessWidget {
  const _TypographyPage();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.palette;
    final roles = <(String, TextStyle?, String)>[
      ('displayLarge · serif', t.displayLarge, 'Every format'),
      ('displayMedium · serif', t.displayMedium, 'one quiet place.'),
      ('displaySmall · serif', t.displaySmall, 'PDF to DOCX'),
      ('headlineLarge · serif', t.headlineLarge, 'Private Vault'),
      ('headlineMedium · serif', t.headlineMedium, 'Converted.'),
      ('headlineSmall · serif', t.headlineSmall, 'Choose a file'),
      ('titleLarge · sans 600', t.titleLarge, 'Recent files'),
      ('titleMedium · sans 600', t.titleMedium, 'Send File'),
      ('titleSmall · sans 600', t.titleSmall, 'Quarterly report.pdf'),
      ('bodyLarge · sans', t.bodyLarge, 'Convert PDF files easily.'),
      ('bodyMedium · sans', t.bodyMedium, 'Share files securely over Wi-Fi.'),
      ('bodySmall · sans muted', t.bodySmall, 'Text · Documents · Images'),
      ('labelLarge · sans 600', t.labelLarge, 'Convert to DOCX'),
      ('labelSmall · mono', t.labelSmall, 'HOME  CONVERT  SHARE'),
      ('AppType.eyebrow · mono', AppType.eyebrow, '02 — RECENT'),
      ('AppType.mono · mono', AppType.mono, 'PDF · 2.4 MB · 72%'),
      ('AppType.numeral · serif', AppType.numeral, '72%'),
    ];

    return Showcase(
      maxWidth: 880,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Three voices, '),
                TextSpan(
                  text: 'one tone.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: p.accent,
                  ),
                ),
              ],
            ),
            style: t.displaySmall,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Instrument Serif for editorial moments, the platform sans '
            '(SF Pro / Roboto) for interface text, IBM Plex Mono for formats, '
            'sizes and counters.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: AppSpace.xl),
          for (final (name, style, sample) in roles) ...[
            Specimen(
              label: '$name · ${style?.fontSize?.toStringAsFixed(1)}',
              child: Text(
                sample,
                style: style?.copyWith(color: style.color ?? p.ink),
              ),
            ),
            const SizedBox(height: AppSpace.lg - 4),
          ],
        ],
      ),
    );
  }
}

class _SpacingPage extends StatelessWidget {
  const _SpacingPage();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const spaces = {
      'xxs': AppSpace.xxs,
      'xs': AppSpace.xs,
      'sm': AppSpace.sm,
      'md': AppSpace.md,
      'lg': AppSpace.lg,
      'xl': AppSpace.xl,
      'xxl': AppSpace.xxl,
      'xxxl': AppSpace.xxxl,
    };
    const radii = {
      'xs': AppRadius.xs,
      'sm': AppRadius.sm,
      'md · controls': AppRadius.md,
      'lg · cards': AppRadius.lg,
      'xl · sheets': AppRadius.xl,
    };

    return Showcase(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spacing', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpace.md),
          for (final e in spaces.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Row(
                children: [
                  SizedBox(width: 64, child: Text(e.key, style: AppType.mono)),
                  Container(width: e.value, height: 16, color: p.accent),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    '${e.value.toInt()}',
                    style: AppType.mono.copyWith(color: p.inkMuted),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.xl),
          Text('Radii', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            children: [
              for (final e in radii.entries)
                Specimen(
                  label: '${e.key} · ${e.value.toInt()}',
                  child: Container(
                    width: 104,
                    height: 72,
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: Border.all(color: p.lineStrong),
                      borderRadius: BorderRadius.circular(e.value),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            'Breakpoints',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'mobile < ${AppBreakpoints.tablet.toInt()} · '
            'tablet < ${AppBreakpoints.desktop.toInt()} · desktop\n'
            'content max width ${AppBreakpoints.content.toInt()} · '
            'min tap target ${AppSize.tapTarget.toInt()}',
            style: AppType.mono.copyWith(color: p.inkMuted, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _MotionPage extends StatefulWidget {
  const _MotionPage();

  @override
  State<_MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends State<_MotionPage> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = {
      'fast · ${AppMotion.fast.inMilliseconds}ms · state changes':
          AppMotion.fast,
      'base · ${AppMotion.base.inMilliseconds}ms · components': AppMotion.base,
      'slow · ${AppMotion.slow.inMilliseconds}ms · emphasis': AppMotion.slow,
    };
    return Showcase(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Motion', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Curve: emphasized (0.2, 0, 0, 1). Durations collapse to zero when '
            'the OS requests reduced motion.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.lg),
          for (final e in rows.entries) ...[
            Specimen(
              label: e.key,
              child: SizedBox(
                height: 28,
                child: AnimatedAlign(
                  duration: AppMotion.of(context, e.value),
                  curve: AppMotion.emphasized,
                  alignment: _on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          FilledButton(
            onPressed: () => setState(() => _on = !_on),
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }
}

class _IconsPage extends StatelessWidget {
  const _IconsPage();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const icons = {
      'home': Icons.home_outlined,
      'convert': Icons.swap_horiz,
      'share': Icons.wifi_tethering,
      'profile': Icons.person_outline,
      'search': Icons.search,
      'upload': Icons.north_east,
      'download': Icons.download_rounded,
      'remove': Icons.close,
      'retry': Icons.refresh,
      'vault': Icons.lock_outline,
      'biometric': Icons.fingerprint,
      'success': Icons.check_circle_outline,
      'warning': Icons.report_gmailerrorred,
      'error': Icons.error_outline,
    };
    return Showcase(
      maxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File glyphs',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.lg,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: const [
              FileGlyph(extension: 'pdf', size: 72),
              FileGlyph(extension: 'docx', size: 56),
              FileGlyph(extension: 'png', size: 44),
              FileGlyph(extension: 'mp3', size: 36),
              FileGlyph(extension: 'zip', size: 30),
              FileGlyph(family: FileFamily.video, size: 30),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            'Interface icons',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Material Icons, outlined where available, 20–22px.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final e in icons.entries)
                Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: AppRadius.control,
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    children: [
                      Icon(e.value, size: 22),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        e.key,
                        style: AppType.mono.copyWith(
                          color: p.inkMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
