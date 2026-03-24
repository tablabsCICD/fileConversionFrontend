import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:flutter/material.dart';
import 'share_file_page.dart';
import 'receive_file_page.dart';

class FileSharingHomePage extends StatelessWidget {
  const FileSharingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveWidget.isDesktop(context) ? 120 : 20,
              vertical: 24,
            ),
            sliver: SliverToBoxAdapter(child: _ActionSection(theme: theme)),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text("File Sharing"),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        background: Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.only(left: 20, bottom: 40),
          alignment: Alignment.bottomLeft,
          child: Text(
            "Share files securely over Wi-Fi or Hotspot",
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final ThemeData theme;
  const _ActionSection({required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveWidget.isDesktop(context);
    final isTablet = ResponsiveWidget.isTablet(context);

    if (isDesktop || isTablet) {
      return Row(
        children: [
          Expanded(child: _ActionCard.send(theme, context)),
          const SizedBox(width: 20),
          Expanded(child: _ActionCard.receive(theme, context)),
        ],
      );
    }

    return Column(
      children: [
        _ActionCard.send(theme, context),
        const SizedBox(height: 16),
        _ActionCard.receive(theme, context),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  factory _ActionCard.send(ThemeData theme, BuildContext context) {
    return _ActionCard(
      icon: Icons.arrow_upward_rounded,
      title: "Send File",
      subtitle: "Make your device discoverable",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShareFilePage()),
        );
      },
    );
  }

  factory _ActionCard.receive(ThemeData theme, BuildContext context) {
    return _ActionCard(
      icon: Icons.arrow_downward_rounded,
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
