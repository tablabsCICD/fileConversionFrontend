import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Story decorator: paper background, Material + Scaffold ancestors (for ink,
/// tooltips and snack bars), centred content with a sensible max width.
class Showcase extends StatelessWidget {
  const Showcase({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.paper,
      body: Align(
        alignment: alignment,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Labelled cell used on token and gallery pages.
class Specimen extends StatelessWidget {
  const Specimen({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppType.eyebrow.copyWith(color: context.palette.inkMuted),
        ),
        const SizedBox(height: AppSpace.xs),
        child,
      ],
    );
  }
}

/// Widgetbook has no Actions panel, so callbacks report themselves in a
/// snack bar and the debug console — the equivalent of Storybook actions.
VoidCallback logAction(BuildContext context, String name) {
  return () {
    debugPrint('[action] $name');
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Action · $name'),
          duration: const Duration(milliseconds: 1400),
        ),
      );
  };
}

ValueChanged<T> logValue<T>(BuildContext context, String name) {
  return (value) => logAction(context, '$name($value)')();
}
