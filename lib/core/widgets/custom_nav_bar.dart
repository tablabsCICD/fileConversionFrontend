import 'dart:ui';
import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Floating, frosted bottom navigation. Must be placed inside a [Stack].
class CustomNavBar extends ConsumerWidget {
  final int index;
  final Function(int) onIndexChanged;

  const CustomNavBar({
    super.key,
    required this.index,
    required this.onIndexChanged,
  });

  static const items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.swap_horiz, Icons.swap_horiz_rounded, 'Convert'),
    (Icons.wifi_tethering, Icons.wifi_tethering, 'Share'),
    (Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final inset = ResponsiveWidget.isMobile(context)
        ? AppSpace.md
        : (width - 520) / 2;

    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom > 0
          ? AppSpace.xs
          : AppSpace.md,
      left: inset,
      right: inset,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.float(Theme.of(context).brightness),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(AppSpace.xs - 2),
                decoration: BoxDecoration(
                  color: p.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: p.line),
                ),
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  label: 'Main navigation',
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(child: _navItem(context, i)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int idx) {
    final p = context.palette;
    final (icon, activeIcon, label) = items[idx];
    final bool active = idx == index;
    final duration = AppMotion.of(context, AppMotion.base);

    return Semantics(
      selected: active,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => onIndexChanged(idx),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => onIndexChanged(idx),
          borderRadius: BorderRadius.circular(AppRadius.lg + 2),
          focusColor: p.accent.withValues(alpha: 0.2),
          hoverColor: p.ink.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.emphasized,
            height: 52,
            decoration: BoxDecoration(
              color: active ? p.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg + 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 21,
                  color: active ? p.paper : p.inkMuted,
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: duration,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontSize: 10,
                    color: active ? p.paper : p.inkMuted,
                  ),
                  child: Text(label, maxLines: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
