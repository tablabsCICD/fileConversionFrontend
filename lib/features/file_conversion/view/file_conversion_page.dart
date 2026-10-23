import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/custom_text_form_field.dart';
import 'package:file_convertor/core/widgets/empty_state.dart';
import 'package:file_convertor/core/widgets/segmented_toggle.dart';
import 'package:file_convertor/core/widgets/toggle_theme_button.dart';
import 'package:file_convertor/features/file_conversion/data/models/conversion_section.dart';
import 'package:file_convertor/features/file_conversion/data/repositories/conversion_sections_list.dart';
import 'package:file_convertor/features/file_conversion/data/services/file_converter.dart';
import 'package:file_convertor/features/file_conversion/view/file_upload_page.dart';
import 'package:file_convertor/features/file_conversion/widgets/conversion_section_card.dart';
import 'package:file_convertor/features/home/widgets/file_upload_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FileConversionPage extends ConsumerStatefulWidget {
  const FileConversionPage({super.key, this.sections});

  /// Defaults to the app's [conversionSections]; injectable for previews.
  final List<ConversionSection>? sections;

  @override
  ConsumerState<FileConversionPage> createState() => _FileConversionPageState();
}

class _FileConversionPageState extends ConsumerState<FileConversionPage> {
  final _searchController = TextEditingController();
  String _query = '';

  /// Show only tools that run on this device.
  bool _onDeviceOnly = false;

  bool _available(ConversionItem item) =>
      ref.read(fileConverterProvider).supports(item.title);

  List<ConversionSection> get _allSections =>
      widget.sections ?? conversionSections;

  /// Sections filtered by the search query. A section-title match keeps the
  /// whole section; otherwise only matching tools are kept.
  List<ConversionSection> get _visibleSections {
    final base = !_onDeviceOnly
        ? _allSections
        : [
            for (final s in _allSections)
              if (s.items.any(_available))
                ConversionSection(
                  title: s.title,
                  items: s.items.where(_available).toList(),
                ),
          ];
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return base;
    final terms = q.split(RegExp(r'\s+'));
    bool matches(String s) => terms.every(s.toLowerCase().contains);

    return [
      for (final section in base)
        if (matches(section.title))
          section
        else if (section.items.any((i) => matches(i.title)))
          ConversionSection(
            title: section.title,
            items: section.items.where((i) => matches(i.title)).toList(),
          ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(ConversionItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FileUploadPage(item: item)),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AppSpace.gutter(width);
    final sections = _visibleSections;
    final toolCount = _allSections.fold<int>(0, (n, s) => n + s.items.length);
    final onDeviceCount = _allSections.fold<int>(
      0,
      (n, s) => n + s.items.where(_available).length,
    );
    final searching = _query.trim().isNotEmpty;
    final columns = ResponsiveWidget.isMobile(context)
        ? (width < 520 ? 1 : 2)
        : ResponsiveWidget.isTablet(context)
        ? 3
        : 4;

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
            titleSpacing: gutter,
            title: Text(
              'TOOLS — $onDeviceCount OF $toolCount ON DEVICE',
              style: AppType.eyebrow.copyWith(color: p.inkMuted),
            ),
            actions: [
              const ToggleThemeButton(),
              SizedBox(width: gutter - AppSpace.xs),
            ],
          ),

          /// --------------------------------------------------
          /// Heading + search
          /// --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpace.xs, gutter, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'What are we\n'),
                          TextSpan(
                            text: 'converting',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: p.accent,
                            ),
                          ),
                          const TextSpan(text: ' today?'),
                        ],
                      ),
                      style: ResponsiveWidget.isMobile(context)
                          ? theme.textTheme.displaySmall
                          : theme.textTheme.displayMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  SegmentedToggle(
                    segments: const ['All tools', 'On device'],
                    selectedIndex: _onDeviceOnly ? 1 : 0,
                    segmentWidth: 116,
                    onChanged: (i) => setState(() => _onDeviceOnly = i == 1),
                  ),
                  const SizedBox(height: AppSpace.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: CustomTextFormField(
                      controller: _searchController,
                      hintText: "Search conversions — try “pdf” or “mp3”",
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      prefix: const Icon(Icons.search),
                      onChanged: (v) => setState(() => _query = v),
                      suffix: searching
                          ? AppIconButton(
                              icon: Icons.close,
                              tooltip: 'Clear search',
                              onPressed: _clearSearch,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                  if (searching) ...[
                    const SizedBox(height: AppSpace.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _resultsLabel(sections),
                        style: AppType.mono.copyWith(color: p.inkMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          /// --------------------------------------------------
          /// Bento / Masonry grid
          /// --------------------------------------------------
          if (sections.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                title: 'No matching tools',
                message:
                    'Nothing matches “${_query.trim()}”. Try a file '
                    'extension such as PDF, PNG or MP4.',
                action: AppButton(
                  label: 'Clear search',
                  variant: AppButtonVariant.secondary,
                  onPressed: _clearSearch,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpace.lg,
                gutter,
                AppSpace.navClearance,
              ),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: columns,
                mainAxisSpacing: ResponsiveWidget.isMobile(context) ? 12 : 16,
                crossAxisSpacing: ResponsiveWidget.isMobile(context) ? 12 : 16,

                /// +1 for the quick-upload card (hidden while searching)
                childCount: sections.length + (searching ? 0 : 1),

                itemBuilder: (context, index) {
                  /// Static card #1
                  if (!searching && index == 0) {
                    return const FileUploadCard(isShort: true);
                  }

                  /// Dynamic conversion sections
                  final section = sections[index - (searching ? 0 : 1)];
                  return ConversionSectionCard(
                    section: section,
                    onSelect: _open,
                    isAvailable: _available,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _resultsLabel(List<ConversionSection> sections) {
    final n = sections.fold<int>(0, (n, s) => n + s.items.length);
    return '$n ${n == 1 ? 'TOOL' : 'TOOLS'} FOUND';
  }
}
