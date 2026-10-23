import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/core/services/file_actions.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/file_tile.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A history entry with open / save / remove actions.
class ActivityTile extends ConsumerWidget {
  const ActivityTile({super.key, required this.entry, this.dense = false});

  final ActivityEntry entry;
  final bool dense;

  static String relativeTime(DateTime at, [DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${at.day}/${at.month}/${at.year}';
  }

  Future<void> _open(BuildContext context) async {
    final path = entry.path;
    if (path == null) return;
    final error = await FileActions.open(path);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _save(BuildContext context) async {
    final path = entry.path;
    if (path == null) return;
    final saved = await FileActions.saveCopyOf(path, fileName: entry.name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved == null ? 'This file no longer exists.' : 'Saved ${entry.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final hasFile = entry.path != null && !kIsWeb;

    return FileTile(
      name: entry.name,
      sizeLabel: FileFormat.formatBytes(entry.sizeBytes),
      caption: '${entry.kind.label.toUpperCase()} · ${relativeTime(entry.at)}',
      dense: dense,
      onTap: hasFile ? () => _open(context) : null,
      trailing: PopupMenuButton<String>(
        tooltip: 'More actions',
        icon: Icon(Icons.more_horiz, color: p.inkMuted),
        onSelected: (action) {
          switch (action) {
            case 'open':
              _open(context);
            case 'save':
              _save(context);
            case 'remove':
              ref.read(activityProvider.notifier).remove(entry.id);
          }
        },
        itemBuilder: (_) => [
          if (hasFile) ...[
            const PopupMenuItem(value: 'open', child: Text('Open')),
            const PopupMenuItem(value: 'save', child: Text('Save a copy')),
          ],
          const PopupMenuItem(
            value: 'remove',
            child: Text('Remove from history'),
          ),
        ],
      ),
    );
  }
}
