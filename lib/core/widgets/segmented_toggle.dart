import 'dart:math' as math;

import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Pill-shaped single-choice control with a sliding thumb.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.segmentWidth = 112,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double segmentWidth;

  static const double _height = 44;
  static const double _inset = 4;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final duration = AppMotion.of(context, AppMotion.base);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Shrink segments to fit narrow screens instead of overflowing.
        final segmentWidth = constraints.hasBoundedWidth
            ? math.min(
                this.segmentWidth,
                (constraints.maxWidth - _inset * 2) / segments.length,
              )
            : this.segmentWidth;
        return Container(
          height: _height,
          padding: const EdgeInsets.all(_inset),
          decoration: BoxDecoration(
            color: p.surfaceSunken,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: AppMotion.emphasized,
                left: selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.ink,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < segments.length; i++)
                    Semantics(
                      selected: i == selectedIndex,
                      inMutuallyExclusiveGroup: true,
                      button: true,
                      child: SizedBox(
                        width: segmentWidth,
                        height: _height - _inset * 2,
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            onTap: () => onChanged(i),
                            focusColor: p.accent.withValues(alpha: 0.2),
                            hoverColor: p.ink.withValues(alpha: 0.04),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: duration,
                                style: text.labelMedium!.copyWith(
                                  color: i == selectedIndex
                                      ? p.paper
                                      : p.inkMuted,
                                ),
                                child: Text(segments[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
