import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tabs of the main navigation shell.
enum AppTab { home, convert, share, profile }

class AppTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}

final appTabProvider = NotifierProvider<AppTabNotifier, AppTab>(
  AppTabNotifier.new,
);
