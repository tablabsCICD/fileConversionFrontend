import 'package:file_convertor/core/widgets/custom_nav_bar.dart';
import 'package:file_convertor/features/file_sharing/view/file_sharing_home_page.dart';
import 'package:file_convertor/features/profile/view/profile_page.dart';
import 'package:file_convertor/features/splash/view/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/view/home_page.dart';
import '../features/file_conversion/view/file_conversion_page.dart';
import 'theme/theme_notifier.dart';
import 'theme/app_theme.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return AnimatedTheme(
      duration: Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      data: themeMode == ThemeMode.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: SplashPage(),
      ),
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    FileConversionPage(),
    FileSharingHomePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          pages[currentIndex],

          // FLOATING BLUR NAVBAR
          CustomNavBar(
            index: currentIndex,
            onIndexChanged: (i) => setState(() => currentIndex = i),
          ),
        ],
      ),
    );
  }
}
