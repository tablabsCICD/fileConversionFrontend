import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/features/home/widgets/storage_overview.dart';
import 'package:file_convertor/features/storage/storage_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Live storage card: loads the snapshot, refreshes when the app returns to
/// the foreground (e.g. after granting access in Settings).
class StorageSection extends ConsumerStatefulWidget {
  const StorageSection({super.key});

  @override
  ConsumerState<StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends ConsumerState<StorageSection> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(storageSnapshotProvider),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(storageSnapshotProvider);

    return snapshot.when(
      data: (data) => StorageOverview(
        snapshot: data,
        onRequestAccess: () => requestMediaAccess(ref),
        onOpenSettings: openAppSettings,
        onRefresh: () => ref.invalidate(storageSnapshotProvider),
      ),
      loading: () => const _Loading(),
      error: (e, _) => InlineNotice(
        tone: NoticeTone.danger,
        title: 'Could not read storage',
        message: '$e',
        action: AppButton(
          label: 'Try again',
          size: AppButtonSize.small,
          variant: AppButtonVariant.secondary,
          onPressed: () => ref.invalidate(storageSnapshotProvider),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Reading storage',
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadius.sheet,
          border: Border.all(color: p.line),
        ),
        alignment: Alignment.center,
        child: const SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
