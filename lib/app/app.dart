import 'package:file_convertor/core/widgets/custom_nav_bar.dart';
import 'package:file_convertor/features/file_sharing/view/file_sharing_home_page.dart';
import 'package:file_convertor/features/profile/view/profile_page.dart';
import 'package:file_convertor/features/splash/view/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/view/home_page.dart';
import '../features/file_conversion/view/file_conversion_page.dart';
import 'navigation.dart';
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
        debugShowCheckedModeBanner: true,
        themeMode: themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: SplashPage(),
      ),
    );
  }
}

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  static const List<Widget> pages = [
    HomePage(),
    FileConversionPage(),
    FileSharingHomePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(appTabProvider);
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Keep each tab alive so scroll position and input survive.
          IndexedStack(index: tab.index, children: pages),

          // FLOATING BLUR NAVBAR
          CustomNavBar(
            index: tab.index,
            onIndexChanged: (i) =>
                ref.read(appTabProvider.notifier).select(AppTab.values[i]),
          ),
        ],
      ),
    );
  }
}
