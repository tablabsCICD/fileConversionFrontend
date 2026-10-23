import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/theme_notifier.dart';

class ToggleThemeButton extends ConsumerWidget {
  const ToggleThemeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final p = context.palette;

    return IconButton(
      onPressed: () => ref.read(themeProvider.notifier).toggleTheme(brightness),
      tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      constraints: const BoxConstraints.tightFor(
        width: AppSize.tapTarget,
        height: AppSize.tapTarget,
      ),
      style: IconButton.styleFrom(
        backgroundColor: p.surfaceSunken,
        hoverColor: p.ink.withValues(alpha: 0.06),
        focusColor: p.accent.withValues(alpha: 0.2),
      ),
      icon: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.base),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween(begin: 0.6, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ValueKey(isDark),
          size: 20,
          color: p.ink,
        ),
      ),
    );
  }
}
