import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/core/widgets/brand_mark.dart';
import 'package:file_convertor/core/widgets/custom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/showcase.dart';

final layout = WidgetbookFolder(
  name: 'Layout',
  children: [
    WidgetbookComponent(
      name: 'Navigation bar',
      useCases: [
        WidgetbookUseCase(
          name: 'Interactive',
          builder: (context) {
            var index = context.knobs.int.slider(
              label: 'Initial tab',
              initialValue: 0,
              min: 0,
              max: 3,
            );
            return Scaffold(
              backgroundColor: context.palette.paper,
              body: StatefulBuilder(
                builder: (context, setState) => Stack(
                  children: [
                    Center(
                      child: Text(
                        CustomNavBar.items[index].$3,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    CustomNavBar(
                      index: index,
                      onIndexChanged: (i) {
                        setState(() => index = i);
                        logValue<int>(context, 'onIndexChanged')(i);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Brand mark',
      useCases: [
        WidgetbookUseCase(
          name: 'Mark',
          builder: (context) => Showcase(
            child: Center(
              child: BrandMark(
                size: context.knobs.double.slider(
                  label: 'Size',
                  initialValue: 40,
                  min: 16,
                  max: 120,
                ),
                showWordmark: context.knobs.boolean(
                  label: 'Wordmark',
                  initialValue: true,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);
