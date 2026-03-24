import 'dart:ui';
import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomNavBar extends ConsumerWidget {
  final int index;
  final Function(int) onIndexChanged;

  const CustomNavBar({
    super.key,
    required this.index,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 16,
      left: ResponsiveWidget.isMobile(context)
          ? 20
          : ResponsiveWidget.isTablet(context)
          ? 150
          : 250,
      right: ResponsiveWidget.isMobile(context)
          ? 20
          : ResponsiveWidget.isTablet(context)
          ? 150
          : 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            decoration: BoxDecoration(
              color: theme.canvasColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.canvasColor.withOpacity(0.2)),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_outlined, "Home", 0, context),
                _navItem(Icons.transform, "Convert", 1, context),
                _navItem(Icons.wifi_tethering, "Share", 2, context),
                _navItem(Icons.person_2_outlined, "Profile", 3, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, BuildContext context) {
    final theme = Theme.of(context);
    final bool active = idx == index;

    return GestureDetector(
      onTap: () => onIndexChanged(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: active
            ? BoxDecoration(
                color: theme.canvasColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.canvasColor, size: active ? 24 : 20),
            if (active)
              Text(
                label,
                style: TextStyle(
                  color: theme.canvasColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
