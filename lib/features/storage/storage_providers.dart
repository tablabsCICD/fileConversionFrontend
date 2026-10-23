import 'package:file_convertor/core/services/device_storage_service.dart';
import 'package:file_convertor/core/services/permissions_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceStorageServiceProvider = Provider<DeviceStorageService>(
  (ref) => const DeviceStorageService(),
);

/// Live storage figures. Invalidate to refresh.
final storageSnapshotProvider = FutureProvider.autoDispose<StorageSnapshot>(
  (ref) => ref.watch(deviceStorageServiceProvider).snapshot(),
);

/// Prompts for media access, then refreshes the snapshot.
Future<MediaAccess> requestMediaAccess(WidgetRef ref) async {
  final access = await PermissionsService.request();
  ref.invalidate(storageSnapshotProvider);
  return access;
}
