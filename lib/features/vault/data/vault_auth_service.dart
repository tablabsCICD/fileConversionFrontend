import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// How the user unlocks the vault — chosen during setup, changeable later.
enum VaultUnlockMethod {
  /// PIN or password only.
  passcode,

  /// Fingerprint / face only (device screen lock as recovery).
  biometric,

  /// Either biometrics or the PIN/password.
  both;

  bool get usesPasscode => this != biometric;
  bool get usesBiometric => this != passcode;
}

enum PasscodeKind {
  /// Exactly 6 digits.
  pin,

  /// At least 6 characters, any kind.
  password,
}

class VaultConfig {
  final VaultUnlockMethod method;

  /// Null when [method] is [VaultUnlockMethod.biometric].
  final PasscodeKind? passcodeKind;

  const VaultConfig({required this.method, this.passcodeKind});
}

/// What the device offers for biometric unlock.
class BiometricSupport {
  final bool available;
  final bool hasFace;
  final bool hasFingerprint;

  /// Why biometrics cannot be used, when [available] is false.
  final String? reason;

  const BiometricSupport({
    required this.available,
    this.hasFace = false,
    this.hasFingerprint = false,
    this.reason,
  });

  String get label => hasFace && !hasFingerprint
      ? 'Face ID'
      : hasFingerprint && !hasFace
      ? 'Fingerprint'
      : 'Fingerprint or face';

  static const none = BiometricSupport(
    available: false,
    reason: 'This device has no fingerprint or face unlock.',
  );
}

sealed class PasscodeResult {
  const PasscodeResult();
}

class PasscodeAccepted extends PasscodeResult {
  const PasscodeAccepted();
}

class PasscodeRejected extends PasscodeResult {
  final int attemptsLeft;
  const PasscodeRejected(this.attemptsLeft);
}

class PasscodeLockedOut extends PasscodeResult {
  final Duration wait;
  const PasscodeLockedOut(this.wait);
}

/// Vault authentication. Secrets live in the Keychain / Android Keystore via
/// flutter_secure_storage; the passcode itself is never stored — only a
/// salted PBKDF2-HMAC-SHA256 hash.
class VaultAuthService {
  VaultAuthService({FlutterSecureStorage? storage, LocalAuthentication? auth})
    : _storage = storage ?? secureStorage,
      _auth = auth ?? LocalAuthentication();

  static const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  static const _kMethod = 'vault_method';
  static const _kKind = 'vault_passcode_kind';
  static const _kHash = 'vault_passcode_hash';
  static const _kSalt = 'vault_passcode_salt';
  static const _kFailures = 'vault_failures';
  static const _kLockedUntil = 'vault_locked_until';

  static const maxAttempts = 5;
  static const _iterations = 60000;

  // ---------------------------------------------------------------------------
  // CONFIG
  // ---------------------------------------------------------------------------

  Future<VaultConfig?> config() async {
    final method = await _storage.read(key: _kMethod);
    if (method == null) return null;
    final kind = await _storage.read(key: _kKind);
    return VaultConfig(
      method: VaultUnlockMethod.values.byName(method),
      passcodeKind: kind == null ? null : PasscodeKind.values.byName(kind),
    );
  }

  /// First-time setup, or changing the method/passcode while unlocked.
  /// Pass [passcode] whenever [method] uses one; omit it to keep the
  /// existing passcode.
  Future<void> configure({
    required VaultUnlockMethod method,
    PasscodeKind? kind,
    String? passcode,
  }) async {
    if (method.usesPasscode) {
      if (passcode != null) {
        if (kind == null) throw ArgumentError('kind is required');
        final error = validatePasscode(passcode, kind);
        if (error != null) throw ArgumentError(error);
        final salt = _randomBytes(16);
        final hash = await _derive(passcode, salt);
        await _storage.write(key: _kSalt, value: base64Encode(salt));
        await _storage.write(key: _kHash, value: base64Encode(hash));
        await _storage.write(key: _kKind, value: kind.name);
      } else if (await _storage.read(key: _kHash) == null) {
        throw ArgumentError('A passcode is required for this method');
      }
    } else {
      await _storage.delete(key: _kHash);
      await _storage.delete(key: _kSalt);
      await _storage.delete(key: _kKind);
    }
    await _storage.write(key: _kMethod, value: method.name);
    await _resetFailures();
  }

  /// Removes all vault credentials (used together with wiping vault files).
  Future<void> reset() async {
    for (final key in [
      _kMethod,
      _kKind,
      _kHash,
      _kSalt,
      _kFailures,
      _kLockedUntil,
    ]) {
      await _storage.delete(key: key);
    }
  }

  /// A user-facing problem with [passcode], or null if acceptable.
  static String? validatePasscode(String passcode, PasscodeKind kind) {
    switch (kind) {
      case PasscodeKind.pin:
        if (!RegExp(r'^\d{6}$').hasMatch(passcode)) {
          return 'PIN must be exactly 6 digits';
        }
        if (RegExp(r'^(\d)\1{5}$').hasMatch(passcode) ||
            '0123456789'.contains(passcode) ||
            '9876543210'.contains(passcode)) {
          return 'Avoid repeated or sequential digits';
        }
      case PasscodeKind.password:
        if (passcode.length < 6) return 'Use at least 6 characters';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // PASSCODE
  // ---------------------------------------------------------------------------

  Future<PasscodeResult> verifyPasscode(String passcode) async {
    final lockedFor = await lockoutRemaining();
    if (lockedFor != null) return PasscodeLockedOut(lockedFor);

    final saltB64 = await _storage.read(key: _kSalt);
    final hashB64 = await _storage.read(key: _kHash);
    if (saltB64 == null || hashB64 == null) return const PasscodeRejected(0);

    final candidate = await _derive(passcode, base64Decode(saltB64));
    if (_constantTimeEquals(candidate, base64Decode(hashB64))) {
      await _resetFailures();
      return const PasscodeAccepted();
    }

    final failures = int.parse(await _storage.read(key: _kFailures) ?? '0') + 1;
    await _storage.write(key: _kFailures, value: '$failures');
    if (failures % maxAttempts == 0) {
      // 30s, 1m, 2m, 4m … capped at 15 minutes.
      final rounds = failures ~/ maxAttempts;
      final seconds = min(30 * pow(2, rounds - 1).toInt(), 15 * 60);
      final until = DateTime.now().add(Duration(seconds: seconds));
      await _storage.write(key: _kLockedUntil, value: until.toIso8601String());
      return PasscodeLockedOut(Duration(seconds: seconds));
    }
    return PasscodeRejected(maxAttempts - failures % maxAttempts);
  }

  /// Time left before another passcode attempt is allowed.
  Future<Duration?> lockoutRemaining() async {
    final raw = await _storage.read(key: _kLockedUntil);
    if (raw == null) return null;
    final left = DateTime.parse(raw).difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  Future<void> _resetFailures() async {
    await _storage.delete(key: _kFailures);
    await _storage.delete(key: _kLockedUntil);
  }

  // ---------------------------------------------------------------------------
  // BIOMETRICS
  // ---------------------------------------------------------------------------

  Future<BiometricSupport> biometricSupport() async {
    if (kIsWeb) return BiometricSupport.none;
    try {
      if (!await _auth.isDeviceSupported()) return BiometricSupport.none;
      if (!await _auth.canCheckBiometrics) return BiometricSupport.none;
      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        return const BiometricSupport(
          available: false,
          reason:
              'No fingerprint or face is enrolled. Add one in your device '
              'settings first.',
        );
      }
      final hasFace = enrolled.contains(BiometricType.face);
      final hasFingerprint =
          enrolled.contains(BiometricType.fingerprint) ||
          enrolled.contains(BiometricType.strong) ||
          enrolled.contains(BiometricType.weak);
      return BiometricSupport(
        available: true,
        hasFace: hasFace,
        hasFingerprint: hasFingerprint || !hasFace,
      );
    } on PlatformException catch (e) {
      return BiometricSupport(available: false, reason: e.message);
    } on MissingPluginException {
      return BiometricSupport.none;
    }
  }

  /// Shows the system biometric prompt. With [allowDeviceCredential] the
  /// device screen lock is accepted too (recovery for biometric-only vaults).
  /// Returns an error message, or null on success.
  Future<String?> authenticateBiometric({
    bool allowDeviceCredential = false,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock your Private Vault',
        options: AuthenticationOptions(
          biometricOnly: !allowDeviceCredential,
          stickyAuth: true,
        ),
      );
      return ok ? null : 'Authentication was cancelled.';
    } on PlatformException catch (e) {
      return switch (e.code) {
        'LockedOut' => 'Too many attempts. Try again in a moment.',
        'PermanentlyLockedOut' =>
          'Biometrics are locked. Unlock your device with its screen lock, '
              'then try again.',
        'NotEnrolled' => 'No fingerprint or face is enrolled on this device.',
        'NotAvailable' ||
        'PasscodeNotSet' => 'Biometric unlock is not available on this device.',
        _ => e.message ?? 'Biometric unlock failed.',
      };
    } on MissingPluginException {
      return 'Biometric unlock is not available on this platform.';
    }
  }

  // ---------------------------------------------------------------------------
  // CRYPTO HELPERS
  // ---------------------------------------------------------------------------

  static Uint8List _randomBytes(int length) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => r.nextInt(256)));
  }

  /// PBKDF2-HMAC-SHA256, one 32-byte block, run off the UI isolate.
  static Future<Uint8List> _derive(String passcode, List<int> salt) {
    final password = utf8.encode(passcode);
    final s = Uint8List.fromList(salt);
    return Isolate.run(() => pbkdf2(password, s, _iterations));
  }

  @visibleForTesting
  static Uint8List pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

final vaultAuthProvider = Provider<VaultAuthService>(
  (ref) => VaultAuthService(),
);
