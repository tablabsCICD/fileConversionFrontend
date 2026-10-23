import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/empty_state.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:file_convertor/features/history/widgets/activity_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every conversion, transfer and vault import, grouped by day.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  ActivityKind? _filter;

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}${d.year == now.year ? '' : ' ${d.year}'}';
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This removes the list of past activity. Converted and received '
          'files stay on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(activityProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final gutter = AppSpace.gutter(MediaQuery.sizeOf(context).width);
    final activity = ref.watch(activityProvider);
    final all = activity.value ?? const <ActivityEntry>[];
    final entries = _filter == null
        ? all
        : all.where((e) => e.kind == _filter).toList();

    final slivers = <Widget>[];
    String? lastDay;
    for (final entry in entries) {
      final day = _dayLabel(entry.at);
      if (day != lastDay) {
        lastDay = day;
        slivers.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpace.lg,
              bottom: AppSpace.sm,
            ),
            child: Text(
              day.toUpperCase(),
              style: AppType.eyebrow.copyWith(color: p.inkMuted),
            ),
          ),
        );
      }
      slivers.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: ActivityTile(entry: entry),
        ),
      );
    }

    final totalBytes = all.fold<int>(0, (n, e) => n + e.sizeBytes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (all.isNotEmpty)
            AppButton(
              label: 'Clear',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.small,
              onPressed: _confirmClear,
            ),
          SizedBox(width: gutter - AppSpace.xs),
        ],
      ),
      body: activity.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpace.xs,
                gutter,
                AppSpace.xxl,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.content,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (all.isNotEmpty) ...[
                          Text(
                            '${all.length} ITEMS · ${FileFormat.formatBytes(totalBytes)}',
                            style: AppType.eyebrow.copyWith(color: p.inkMuted),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Wrap(
                            spacing: AppSpace.xs,
                            runSpacing: AppSpace.xs,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: _filter == null,
                                onSelected: (_) =>
                                    setState(() => _filter = null),
                              ),
                              for (final kind in ActivityKind.values)
                                if (all.any((e) => e.kind == kind))
                                  ChoiceChip(
                                    label: Text(kind.label),
                                    selected: _filter == kind,
                                    onSelected: (_) =>
                                        setState(() => _filter = kind),
                                  ),
                            ],
                          ),
                        ],
                        if (entries.isEmpty)
                          const EmptyState(
                            icon: Icons.history,
                            title: 'Nothing here yet',
                            message:
                                'Files you convert, send, receive or add to '
                                'the vault will appear here.',
                          )
                        else
                          ...slivers,
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
