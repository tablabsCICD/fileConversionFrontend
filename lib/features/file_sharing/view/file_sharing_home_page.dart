import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/core/widgets/toggle_theme_button.dart';
import 'package:flutter/material.dart';
import 'share_file_page.dart';
import 'receive_file_page.dart';

class FileSharingHomePage extends StatelessWidget {
  const FileSharingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final gutter = AppSpace.gutter(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            titleSpacing: gutter,
            title: Text(
              'SHARE — LOCAL NETWORK',
              style: AppType.eyebrow.copyWith(color: p.inkMuted),
            ),
            actions: [
              const ToggleThemeButton(),
              SizedBox(width: gutter - AppSpace.xs),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpace.xs,
              gutter,
              AppSpace.navClearance,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Pass files\n'),
                              TextSpan(
                                text: 'across the room.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: p.accent,
                                ),
                              ),
                            ],
                          ),
                          style: ResponsiveWidget.isMobile(context)
                              ? theme.textTheme.displaySmall
                              : theme.textTheme.displayMedium,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        "Share files securely over Wi-Fi or Hotspot",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: p.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      const _ActionSection(),
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

class _ActionSection extends StatelessWidget {
  const _ActionSection();

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveWidget.isDesktop(context);
    final isTablet = ResponsiveWidget.isTablet(context);

    if (isDesktop || isTablet) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _ActionCard.send(context)),
            const SizedBox(width: AppSpace.md),
            Expanded(child: _ActionCard.receive(context)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _ActionCard.send(context),
        const SizedBox(height: AppSpace.sm),
        _ActionCard.receive(context),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String index;
  final String title;
  final String subtitle;
  final bool emphasized;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  factory _ActionCard.send(BuildContext context) {
    return _ActionCard(
      icon: Icons.north_east,
      index: '01',
      title: "Send File",
      subtitle: "Make your device discoverable",
      emphasized: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShareFilePage()),
        );
      },
    );
  }

  factory _ActionCard.receive(BuildContext context) {
    return _ActionCard(
      icon: Icons.south_west,
      index: '02',
      title: "Receive File",
      subtitle: "Connect to nearby sender",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReceiveFilePage()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bg = emphasized ? p.ink : p.surface;
    final fg = emphasized ? p.paper : p.ink;
    final muted = emphasized ? p.paper.withValues(alpha: 0.72) : p.inkMuted;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sheet,
          side: emphasized ? BorderSide.none : BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: fg.withValues(alpha: 0.04),
          focusColor: p.accent.withValues(alpha: 0.24),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg - 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(index, style: AppType.eyebrow.copyWith(color: muted)),
                    const Spacer(),
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: emphasized ? p.accent : p.surfaceSunken,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: emphasized ? p.onAccent : p.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                Text(title, style: text.headlineMedium?.copyWith(color: fg)),
                const SizedBox(height: AppSpace.xxs),
                Text(subtitle, style: text.bodyMedium?.copyWith(color: muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
