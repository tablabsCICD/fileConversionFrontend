import 'dart:async';
import 'package:file_convertor/app/navigation.dart';
import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/brand_mark.dart';
import 'package:file_convertor/core/widgets/empty_state.dart';
import 'package:file_convertor/core/widgets/section_header.dart';
import 'package:file_convertor/core/widgets/segmented_toggle.dart';
import 'package:file_convertor/core/widgets/toggle_theme_button.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:file_convertor/features/history/view/history_page.dart';
import 'package:file_convertor/features/history/widgets/activity_tile.dart';
import 'package:file_convertor/features/home/data/models/banner_data.dart';
import 'package:file_convertor/features/home/widgets/file_upload_card.dart';
import 'package:file_convertor/features/storage/storage_section.dart';
import 'package:file_convertor/features/vault/view/vault_lock_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _pageController = PageController();
  Timer? _timer;

  int _currentBanner = 0;
  int _storageTabIndex = 0; // 0 = Convert, 1 = Storage

  final List<BannerData> banners = const [
    BannerData(
      title: "Convert on your device",
      subtitle: "Images, PDF, documents & data — no upload",
      icon: Icons.transform,
      image: 'assets/images/poster1.jpg',
    ),
    BannerData(
      title: "Share over Wi-Fi",
      subtitle: "Direct device-to-device transfer",
      icon: Icons.wifi_tethering,
      image: 'assets/images/poster2.jpg',
    ),
    BannerData(
      title: "Private Vault",
      subtitle: "AES-256 encrypted · PIN, password or fingerprint",
      icon: Icons.lock_outline,
      image: 'assets/images/poster3.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Respect reduced-motion: no auto-advancing carousel.
      if (!mounted || AppMotion.reduced(context)) return;
      if (!_pageController.hasClients) return;
      _currentBanner = (_currentBanner + 1) % banners.length;
      _pageController.animateToPage(
        _currentBanner,
        duration: AppMotion.slow * 2,
        curve: AppMotion.emphasized,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openBanner(int index) {
    switch (index) {
      case 0:
        ref.read(appTabProvider.notifier).select(AppTab.convert);
      case 1:
        ref.read(appTabProvider.notifier).select(AppTab.share);
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VaultLockPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AppSpace.gutter(width);

    Widget constrained(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            titleSpacing: gutter,
            title: const BrandMark(size: 26),
            actions: [
              const ToggleThemeButton(),
              SizedBox(width: gutter - AppSpace.xs),
            ],
          ),
          SliverToBoxAdapter(child: constrained(_intro(context))),
          SliverToBoxAdapter(child: constrained(_bannerSection())),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpace.xl,
                bottom: AppSpace.lg,
              ),
              child: Center(
                child: SegmentedToggle(
                  segments: const ['Convert', 'Storage'],
                  selectedIndex: _storageTabIndex,
                  onChanged: (i) => setState(() => _storageTabIndex = i),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: constrained(
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                child: _storageTabIndex == 1
                    ? const StorageSection(key: ValueKey('storage'))
                    : const FileUploadCard(key: ValueKey('upload')),
              ),
            ),
          ),
          SliverToBoxAdapter(child: constrained(_recentSection())),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpace.navClearance),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INTRO
  // ------------------------------------------------------------
  Widget _intro(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.lg),
      child: Semantics(
        header: true,
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Every format,\n'),
              TextSpan(
                text: 'one',
                style: TextStyle(fontStyle: FontStyle.italic, color: p.accent),
              ),
              const TextSpan(text: ' quiet place.'),
            ],
          ),
          style: ResponsiveWidget.isMobile(context)
              ? text.displaySmall
              : text.displayMedium,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BANNER
  // ------------------------------------------------------------
  Widget _bannerSection() {
    final p = context.palette;
    final height = ResponsiveWidget.isMobile(context) ? 208.0 : 280.0;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemBuilder: (_, i) => _bannerCard(banners[i], i),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < banners.length; i++)
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.base),
                  curve: AppMotion.emphasized,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentBanner ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentBanner ? p.ink : p.lineStrong,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerCard(BannerData data, int index) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          'Slide ${index + 1} of ${banners.length}: '
          '${data.title}. ${data.subtitle}',
      excludeSemantics: true,
      onTap: () => _openBanner(index),
      child: ClipRRect(
        borderRadius: AppRadius.sheet,
        child: Stack(
          fit: StackFit.expand,
          children: [
            /// Background image
            Image.asset(data.image, fit: BoxFit.cover),

            /// Gradient overlay — enough density for white text contrast.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.2, 1],
                  colors: [Color(0x00000000), Color(0xCC0B0B0A)],
                ),
              ),
            ),

            /// Text content
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(data.icon, color: Colors.white, size: 16),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        '${(index + 1).toString().padLeft(2, '0')} / '
                        '${banners.length.toString().padLeft(2, '0')}',
                        style: AppType.eyebrow.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    data.title,
                    style: text.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.subtitle,
                          style: text.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// Ink for tap feedback above the image.
            Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: () => _openBanner(index)),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RECENT ACTIVITY
  // ------------------------------------------------------------
  Widget _recentSection() {
    final wide = !ResponsiveWidget.isMobile(context);
    final activity = ref.watch(activityProvider);
    final entries = (activity.value ?? const <ActivityEntry>[])
        .take(wide ? 6 : 4)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Recent',
            title: 'Recent activity',
            trailing: entries.isEmpty
                ? null
                : AppButton(
                    label: 'View all',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    ),
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    trailingIcon: Icons.arrow_forward,
                  ),
          ),
          const SizedBox(height: AppSpace.md),
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.history,
              title: 'No activity yet',
              message:
                  'Convert, share or receive a file and it will show up here.',
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                const gap = AppSpace.sm;
                final w = wide ? (c.maxWidth - gap) / 2 : c.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final e in entries)
                      SizedBox(
                        width: w,
                        child: ActivityTile(entry: e),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
