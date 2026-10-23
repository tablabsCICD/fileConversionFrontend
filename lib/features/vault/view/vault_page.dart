import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/services/file_actions.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/empty_state.dart';
import 'package:file_convertor/core/widgets/file_tile.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:file_convertor/features/storage/storage_providers.dart';
import 'package:file_convertor/features/vault/data/vault_repository.dart';
import 'package:file_convertor/features/vault/view/vault_lock_page.dart';
import 'package:file_convertor/features/vault/view/vault_settings_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The unlocked vault: encrypted files you can add, open, export and delete.
/// Locks itself when the app goes to the background.
class VaultPage extends ConsumerStatefulWidget {
  const VaultPage({super.key});

  @override
  ConsumerState<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<VaultPage> {
  List<VaultItem>? _items;
  String? _error;
  String? _busyLabel;

  /// Opening a file hands control to another app; don't lock for that.
  bool _externalViewer = false;

  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: () {
      if (!_externalViewer) _lock();
    },
    onResume: () => _externalViewer = false,
  );

  VaultRepository get _repo => ref.read(vaultRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
    _reload();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _repo.clearPreviews();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final items = await _repo.list();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = const [];
          _error = 'The vault index could not be read.';
        });
      }
    }
  }

  void _lock() {
    _repo.clearPreviews();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VaultLockPage()),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    _externalViewer = true; // the picker backgrounds the app on some devices
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    _externalViewer = false;
    if (result == null || !mounted) return;

    var added = 0;
    for (final f in result.files) {
      if (f.path == null) continue;
      setState(() => _busyLabel = 'Encrypting ${f.name}…');
      try {
        final item = await _repo.add(f.path!, name: f.name);
        added++;
        ref
            .read(activityProvider.notifier)
            .add(
              ActivityEntry.create(
                kind: ActivityKind.vaulted,
                name: item.name,
                sizeBytes: item.sizeBytes,
              ),
            );
      } on VaultFileTooLarge catch (e) {
        _toast(e.toString());
      } catch (_) {
        _toast('Could not add ${f.name}.');
      }
    }
    if (!mounted) return;
    setState(() => _busyLabel = null);
    ref.invalidate(storageSnapshotProvider);
    await _reload();
    if (added > 0) {
      _toast(
        '$added ${added == 1 ? 'file' : 'files'} encrypted. The originals are '
        'unchanged — delete them yourself if you no longer need them.',
      );
    }
  }

  Future<void> _open(VaultItem item) async {
    setState(() => _busyLabel = 'Decrypting ${item.name}…');
    try {
      final file = await _repo.decryptToPreview(item);
      if (!mounted) return;
      setState(() => _busyLabel = null);
      _externalViewer = true;
      final error = await FileActions.open(file.path);
      if (error != null && mounted) _toast(error);
    } catch (_) {
      if (mounted) {
        setState(() => _busyLabel = null);
        _toast('${item.name} could not be decrypted.');
      }
    }
  }

  Future<void> _export(VaultItem item) async {
    setState(() => _busyLabel = 'Decrypting ${item.name}…');
    try {
      final bytes = await _repo.read(item);
      if (!mounted) return;
      setState(() => _busyLabel = null);
      _externalViewer = true;
      final saved = await FileActions.saveCopy(
        fileName: item.name,
        bytes: bytes,
      );
      _externalViewer = false;
      if (saved != null && mounted) {
        _toast('Saved an unencrypted copy of ${item.name}.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busyLabel = null);
        _toast('${item.name} could not be exported.');
      }
    }
  }

  Future<void> _delete(VaultItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: const Text('It will be permanently removed from the vault.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.palette.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(item);
    ref.invalidate(storageSnapshotProvider);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final gutter = AppSpace.gutter(MediaQuery.sizeOf(context).width);
    final items = _items;
    final total = items?.fold<int>(0, (n, i) => n + i.sizeBytes) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PRIVATE VAULT',
          style: AppType.eyebrow.copyWith(color: p.inkMuted),
        ),
        actions: [
          AppIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Vault settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VaultSettingsPage(onLockNow: _lock),
              ),
            ).then((_) => _reload()),
          ),
          AppIconButton(
            icon: Icons.lock_outline,
            tooltip: 'Lock vault',
            onPressed: _lock,
          ),
          SizedBox(width: gutter - AppSpace.xs),
        ],
      ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton.extended(
              onPressed: _busyLabel == null ? _add : null,
              backgroundColor: p.ink,
              foregroundColor: p.paper,
              icon: const Icon(Icons.add),
              label: const Text('Add files'),
            ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(gutter, AppSpace.xs, gutter, 120),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.content,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Your vault',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          '${items.length} ${items.length == 1 ? 'FILE' : 'FILES'} · '
                          '${FileFormat.formatBytes(total)} · AES-256',
                          style: AppType.eyebrow.copyWith(color: p.inkMuted),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        if (_busyLabel != null) ...[
                          InlineNotice(title: _busyLabel!),
                          const SizedBox(height: AppSpace.sm),
                        ],
                        if (_error != null) ...[
                          InlineNotice(tone: NoticeTone.danger, title: _error!),
                          const SizedBox(height: AppSpace.sm),
                        ],
                        if (items.isEmpty)
                          EmptyState(
                            icon: Icons.lock_outline,
                            title: 'Nothing locked away yet',
                            message:
                                'Add photos, documents or anything else. Each '
                                'file is encrypted before it is stored.',
                            action: kIsWeb
                                ? null
                                : AppButton(
                                    label: 'Add files',
                                    icon: Icons.add,
                                    onPressed: _add,
                                  ),
                          )
                        else
                          for (final item in items) ...[
                            FileTile(
                              name: item.name,
                              sizeLabel: FileFormat.formatBytes(item.sizeBytes),
                              caption: 'Added ${_date(item.addedAt)}',
                              onTap: () => _open(item),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'File actions',
                                icon: Icon(Icons.more_horiz, color: p.inkMuted),
                                onSelected: (a) => switch (a) {
                                  'open' => _open(item),
                                  'export' => _export(item),
                                  _ => _delete(item),
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'open',
                                    child: Text('Open'),
                                  ),
                                  PopupMenuItem(
                                    value: 'export',
                                    child: Text('Save a copy'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.xs),
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
