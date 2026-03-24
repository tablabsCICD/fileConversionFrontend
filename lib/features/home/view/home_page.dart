import 'dart:async';
import 'dart:ui';
import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/core/widgets/login_button.dart';
import 'package:file_convertor/core/widgets/toggle_theme_button.dart';
import 'package:file_convertor/features/home/data/models/banner_data.dart';
import 'package:file_convertor/features/home/data/models/file_data.dart';
import 'package:file_convertor/features/home/widgets/file_upload_card.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  Timer? _timer;

  int _currentBanner = 0;
  int _storageTabIndex = 0; // 0 = Files, 1 = Storage
  bool isLoggedIn = true;

  final List<BannerData> banners = const [
    BannerData(
      title: "Convert any file instantly",
      subtitle: "PDF, DOCX, JPG & more",
      icon: Icons.transform,
      image: 'assets/images/poster1.jpg',
    ),
    BannerData(
      title: "Share files at 200 Mbps",
      subtitle: "Ultra-fast & secure transfer",
      icon: Icons.flash_on,
      image: 'assets/images/poster2.jpg',
    ),
    BannerData(
      title: "Private Vault",
      subtitle: "AES-256 encrypted storage",
      icon: Icons.lock_outline,
      image: 'assets/images/poster3.jpg',
    ),
  ];

  final List<FileData> recentFiles = List.generate(
    5,
    (i) => FileData(
      name: "Document_$i.pdf",
      size: "${(i + 1) * 2} MB",
      type: "PDF",
      icon: Icons.picture_as_pdf,
      color: Colors.redAccent,
    ),
  );

  final List<_StorageItem> storageItems = const [
    _StorageItem("Images", Icons.image, Colors.blue, "1.2 GB"),
    _StorageItem("Documents", Icons.description, Colors.orange, "820 MB"),
    _StorageItem("Music", Icons.music_note, Colors.purple, "420 MB"),
    _StorageItem("Videos", Icons.videocam, Colors.red, "1.6 GB"),
    _StorageItem("Archives", Icons.archive, Colors.green, "260 MB"),
    _StorageItem("Others", Icons.folder, Colors.grey, "180 MB"),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _currentBanner = (_currentBanner + 1) % banners.length;
      _pageController.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            actions: [
              isLoggedIn ? Icon(Icons.search, size: 26) : LoginButton(),
              SizedBox(width: 12),
              ToggleThemeButton(),
              SizedBox(width: 12),
            ],
          ),
          SliverToBoxAdapter(child: _bannerSection()),
          SliverToBoxAdapter(
            child: Column(
              children: [_storageToggle(theme), const SizedBox(height: 28)],
            ),
          ),
          _storageTabIndex == 1
              ? SliverToBoxAdapter(child: _storageSection(theme))
              : SliverToBoxAdapter(child: FileUploadCard()),
          SliverToBoxAdapter(child: _recentFilesSection(theme)),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BANNER
  // ------------------------------------------------------------
  Widget _bannerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _currentBanner = i),
              itemBuilder: (_, i) => _bannerCard(banners[i]),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STORAGE
  // ------------------------------------------------------------
  Widget _storageSection(ThemeData theme) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              _storageProgress(theme),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: theme.canvasColor.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Total Storage',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text('5 GB'),
                    ],
                  ),

                  SizedBox(
                    width: ResponsiveWidget.isMobile(context) ? 100 : 160,
                  ),

                  Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Used Storage',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text('3.5 GB'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _storageGrid(theme),
            ],
          ),
        ),

        if (!isLoggedIn)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: theme.scaffoldBackgroundColor.withOpacity(0.28),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 42,
                        color: theme.canvasColor,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Login to unlock your storage',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Get up to 5 GB of secure cloud storage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      LoginButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _storageToggle(ThemeData theme) {
    return GestureDetector(
      onTap: () =>
          setState(() => _storageTabIndex = _storageTabIndex == 0 ? 1 : 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.cardColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleItem("Convert", _storageTabIndex == 0),
            _toggleItem("Storage", _storageTabIndex == 1),
          ],
        ),
      ),
    );
  }

  Widget _storageProgress(ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 130,
          width: 130,
          child: CircularProgressIndicator(
            value: 0.72,
            strokeWidth: 14,
            strokeCap: StrokeCap.round,
            backgroundColor: theme.canvasColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(theme.primaryColor),
          ),
        ),
        Column(
          children: const [
            Text(
              "72%",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text("Used of 5 GB", style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _storageGrid(ThemeData theme) {
    return SizedBox(
      width: ResponsiveWidget.isMobile(context) ? double.infinity : 700,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: storageItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveWidget.isMobile(context) ? 2 : 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 9 / 2,
          ),
          itemBuilder: (_, i) {
            final item = storageItems[i];
            return Container(
              //padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 8),
                  Icon(item.icon, color: item.color, size: 22),
                  SizedBox(width: 8),
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Text(
                    item.size,
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RECENT FILES
  // ------------------------------------------------------------
  Widget _recentFilesSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Files",
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "View all",
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentFiles.map((f) => _recentFileCard(f, theme)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // WIDGETS
  // ------------------------------------------------------------
  Widget _toggleItem(String text, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: active ? Colors.blue : Colors.transparent,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _bannerCard(BannerData data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0, end: 1),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            /// Background image
            Image.asset(data.image, fit: BoxFit.cover),

            /// Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),

            /// Text content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentFileCard(FileData file, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(file.icon, color: file.color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, overflow: TextOverflow.ellipsis),
                Text(file.size, style: TextStyle(color: theme.hintColor)),
              ],
            ),
          ),
          const Icon(Icons.more_vert),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// STORAGE MODEL
// ------------------------------------------------------------
class _StorageItem {
  final String title;
  final IconData icon;
  final Color color;
  final String size;

  const _StorageItem(this.title, this.icon, this.color, this.size);
}
