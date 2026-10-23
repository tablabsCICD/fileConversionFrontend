// Widgetbook — the component workbench (Flutter's Storybook equivalent).
//
// Run:    flutter run -t widgetbook/main.dart -d chrome   (or -d macos)
// Build:  flutter build web -t widgetbook/main.dart -o build/widgetbook

import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:file_convertor/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stories/components.dart';
import 'stories/design_system.dart';
import 'stories/features.dart';
import 'stories/file_converter.dart';
import 'stories/layout.dart';
import 'stories/screens.dart';

void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        designSystem,
        components,
        layout,
        fileConverter,
        features,
        screens,
      ],
      // Same ProviderScope as the app, so Riverpod-backed widgets render.
      appBuilder: (context, child) =>
          ProviderScope(child: materialAppBuilder(context, child)),
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light · Paper', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'Dark · Ink', data: AppTheme.darkTheme),
          ],
        ),
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhoneSE,
          IosViewports.iPhone13,
          AndroidViewports.samsungGalaxyA50,
          IosViewports.iPadAir4,
          MacosViewports.macbookPro,
        ]),
        TextScaleAddon(min: 1, max: 2, divisions: 4),
        // Flags small tap targets, missing labels and unlabeled inputs.
        BuilderAddon(
          name: 'Accessibility',
          builder: (context, child) =>
              AccessibilityTools(checkFontOverflows: true, child: child),
        ),
        InspectorAddon(),
        GridAddon(8),
        ZoomAddon(),
      ],
    );
  }
}
