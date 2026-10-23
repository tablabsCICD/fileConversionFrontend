import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_convertor/core/services/app_directories.dart';
import 'package:file_convertor/features/vault/data/vault_auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VaultItem {
  final String id;
  final String name;
  final int sizeBytes;
  final DateTime addedAt;

  const VaultItem({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.addedAt,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'size': sizeBytes,
    'added': addedAt.toIso8601String(),
  };

  static VaultItem fromJson(Map<String, Object?> json) => VaultItem(
    id: json['id'] as String,
    name: json['name'] as String,
    sizeBytes: (json['size'] as num).toInt(),
    addedAt: DateTime.parse(json['added'] as String),
  );
}

class VaultFileTooLarge implements Exception {
  final String name;
  const VaultFileTooLarge(this.name);
  @override
  String toString() =>
      '“$name” is larger than ${VaultRepository.maxFileBytes ~/ (1024 * 1024)} MB.';
}

/// Encrypted file storage. Each file (and the index of names) is sealed with
/// AES-256-GCM using a random key kept in the Keychain / Android Keystore.
/// Files sit in Application Support, invisible to the gallery and Files app.
class VaultRepository {
  VaultRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? VaultAuthService.secureStorage;

  final FlutterSecureStorage _storage;

  static const _kKey = 'vault_data_key';
  static const _indexName = 'index.bin';

  /// Files are encrypted in memory, so keep them to a sensible size.
  static const maxFileBytes = 200 * 1024 * 1024;

  Future<Uint8List> _key() async {
    final existing = await _storage.read(key: _kKey);
    if (existing != null) return base64Decode(existing);
    final r = Random.secure();
    final key = Uint8List.fromList(List.generate(32, (_) => r.nextInt(256)));
    await _storage.write(key: _kKey, value: base64Encode(key));
    return key;
  }

  Future<List<VaultItem>> list() async {
    final file = File('${(await AppDirectories.vault()).path}/$_indexName');
    if (!await file.exists()) return [];
    final plain = await _decrypt(await file.readAsBytes(), await _key());
    final raw = jsonDecode(utf8.decode(plain)) as List;
    return [
      for (final item in raw) VaultItem.fromJson(item as Map<String, Object?>),
    ]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Future<void> _writeIndex(List<VaultItem> items) async {
    final dir = await AppDirectories.vault();
    final bytes = utf8.encode(jsonEncode([for (final i in items) i.toJson()]));
    final sealed = await _encrypt(bytes, await _key());
    final tmp = File('${dir.path}/$_indexName.tmp');
    await tmp.writeAsBytes(sealed, flush: true);
    await tmp.rename('${dir.path}/$_indexName');
  }

  /// Encrypts a copy of the file at [path] into the vault.
  Future<VaultItem> add(String path, {String? name}) async {
    final source = File(path);
    final length = await source.length();
    final fileName = name ?? source.uri.pathSegments.last;
    if (length > maxFileBytes) throw VaultFileTooLarge(fileName);

    final key = await _key();
    final dir = await AppDirectories.vault();
    final id = '${DateTime.now().microsecondsSinceEpoch}';
    final target = '${dir.path}/$id.bin';

    await Isolate.run(() async {
      final data = await File(path).readAsBytes();
      await File(target).writeAsBytes(_seal(data, key), flush: true);
    });

    final item = VaultItem(
      id: id,
      name: fileName,
      sizeBytes: length,
      addedAt: DateTime.now(),
    );
    await _writeIndex([item, ...await list()]);
    return item;
  }

  Future<Uint8List> read(VaultItem item) async {
    final file = File('${(await AppDirectories.vault()).path}/${item.id}.bin');
    return _decrypt(await file.readAsBytes(), await _key());
  }

  /// Decrypts [item] to a temporary file for previewing.
  Future<File> decryptToPreview(VaultItem item) async {
    final dir = await AppDirectories.vaultPreview();
    final out = File('${dir.path}/${item.name}');
    await out.writeAsBytes(await read(item), flush: true);
    return out;
  }

  /// Wipes every decrypted preview. Called on every lock.
  Future<void> clearPreviews() async {
    final dir = await AppDirectories.vaultPreview();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> delete(VaultItem item) async {
    final file = File('${(await AppDirectories.vault()).path}/${item.id}.bin');
    if (await file.exists()) await file.delete();
    await _writeIndex((await list()).where((i) => i.id != item.id).toList());
  }

  /// Deletes every vault file and the encryption key.
  Future<void> wipe() async {
    final dir = await AppDirectories.vault();
    if (await dir.exists()) await dir.delete(recursive: true);
    await clearPreviews();
    await _storage.delete(key: _kKey);
  }

  static Future<Uint8List> _encrypt(List<int> data, Uint8List key) =>
      Isolate.run(() => _seal(data, key));

  static Future<Uint8List> _decrypt(Uint8List sealed, Uint8List key) =>
      Isolate.run(() => _open(sealed, key));

  /// `iv (12 bytes) || ciphertext+tag`
  static Uint8List _seal(List<int> data, Uint8List key) {
    final iv = enc.IV.fromSecureRandom(12);
    final cipher = enc.Encrypter(
      enc.AES(enc.Key(key), mode: enc.AESMode.gcm),
    ).encryptBytes(data, iv: iv);
    return Uint8List.fromList([...iv.bytes, ...cipher.bytes]);
  }

  static Uint8List _open(Uint8List sealed, Uint8List key) {
    final iv = enc.IV(Uint8List.sublistView(sealed, 0, 12));
    final body = enc.Encrypted(Uint8List.sublistView(sealed, 12));
    return Uint8List.fromList(
      enc.Encrypter(
        enc.AES(enc.Key(key), mode: enc.AESMode.gcm),
      ).decryptBytes(body, iv: iv),
    );
  }
}

final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => VaultRepository(),
);
