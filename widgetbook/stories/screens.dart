import 'package:file_convertor/app/app.dart';
import 'package:file_convertor/features/file_conversion/view/file_conversion_page.dart';
import 'package:file_convertor/features/file_sharing/view/file_sharing_home_page.dart';
import 'package:file_convertor/features/file_sharing/view/receive_file_page.dart';
import 'package:file_convertor/features/file_sharing/view/share_file_page.dart';
import 'package:file_convertor/features/home/view/home_page.dart';
import 'package:file_convertor/features/profile/view/profile_page.dart';
import 'package:file_convertor/features/vault/view/vault_lock_page.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Full screens. Pick a device in the Viewport addon to review layouts.
final screens = WidgetbookFolder(
  name: 'Screens',
  children: [
    WidgetbookComponent(
      name: 'App shell',
      useCases: [
        WidgetbookUseCase(
          name: 'Main navigation',
          builder: (context) => const MainNavigation(),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Home',
      useCases: [
        WidgetbookUseCase(
          name: 'Home',
          builder: (context) => const Scaffold(body: HomePage()),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Convert',
      useCases: [
        WidgetbookUseCase(
          name: 'Tool catalogue',
          builder: (context) => const FileConversionPage(),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Share',
      useCases: [
        WidgetbookUseCase(
          name: 'Hub',
          builder: (context) => const FileSharingHomePage(),
        ),
        WidgetbookUseCase(
          name: 'Send · choose file',
          builder: (context) => const ShareFilePage(),
        ),
        WidgetbookUseCase(
          name: 'Receive',
          builder: (context) => const ReceiveFilePage(),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Profile',
      useCases: [
        WidgetbookUseCase(
          name: 'Profile',
          builder: (context) => const ProfilePage(),
        ),
        WidgetbookUseCase(
          name: 'Vault · first run',
          builder: (context) => const VaultLockPage(),
        ),
      ],
    ),
  ],
);
