import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/core/widgets/custom_text_form_field.dart';
import 'package:file_convertor/core/widgets/login_button.dart';
import 'package:file_convertor/core/widgets/toggle_theme_button.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_section.dart';
import 'package:file_convertor/features/file_conversion/data/repositories/conversion_sections_list.dart';
import 'package:file_convertor/features/file_conversion/view/file_upload_page.dart';
import 'package:file_convertor/features/home/widgets/file_upload_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FileConversionPage extends StatelessWidget {
  const FileConversionPage({super.key});
  final bool isLoggedIn = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          /// --------------------------------------------------
          /// App bar
          /// --------------------------------------------------
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            actions: [
              isLoggedIn ? const Icon(Icons.search, size: 26) : LoginButton(),
              const SizedBox(width: 12),
              const ToggleThemeButton(),
              const SizedBox(width: 12),
            ],
          ),

          /// --------------------------------------------------
          /// Search bar
          /// --------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: CustomTextFormField(
                controller: TextEditingController(),
                hintText: "Search conversions…",
                keyboardType: TextInputType.text,
                prefix: const Icon(Icons.search),
              ),
            ),
          ),

          /// --------------------------------------------------
          /// Bento / Masonry grid
          /// --------------------------------------------------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 90),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: ResponsiveWidget.isMobile(context)
                  ? 2
                  : ResponsiveWidget.isTablet(context)
                  ? 3
                  : 4,
              mainAxisSpacing: ResponsiveWidget.isMobile(context) ? 8 : 16,
              crossAxisSpacing: ResponsiveWidget.isMobile(context) ? 8 : 16,

              /// 🔥 +2 for static cards
              childCount: conversionSections.length + 1,

              itemBuilder: (context, index) {
                /// Static card #1
                if (index == 0) {
                  return FileUploadCard(isShort: true);
                }

                /// Dynamic conversion sections
                final section = conversionSections[index - 1];
                return _BentoSectionCard(section: section);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoSectionCard extends StatelessWidget {
  final ConversionSection section;

  const _BentoSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Section title
          Text(
            section.title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.hintColor,
            ),
          ),

          const SizedBox(height: 16),

          /// Tools
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ToolRow(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final ConversionItem item;

  const _ToolRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FileUploadPage(item: item)),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
