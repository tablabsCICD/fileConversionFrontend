import 'dart:convert';

import 'package:file_convertor/app/theme/app_theme.dart';
import 'package:file_convertor/core/services/device_storage_service.dart';
import 'package:file_convertor/core/services/permissions_service.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:file_convertor/features/home/widgets/storage_overview.dart';
import 'package:file_convertor/features/profile/data/profile.dart';
import 'package:file_convertor/features/vault/data/vault_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vault security', () {
    test('PBKDF2-HMAC-SHA256 matches published test vectors', () {
      final p = utf8.encode('password');
      final s = utf8.encode('salt');
      expect(
        _hex(VaultAuthService.pbkdf2(p, s, 1)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        _hex(VaultAuthService.pbkdf2(p, s, 2)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('passcode rules', () {
      String? check(String v, PasscodeKind k) =>
          VaultAuthService.validatePasscode(v, k);
      expect(check('482913', PasscodeKind.pin), isNull);
      expect(check('12345', PasscodeKind.pin), isNotNull);
      expect(check('123456', PasscodeKind.pin), isNotNull);
      expect(check('777777', PasscodeKind.pin), isNotNull);
      expect(check('12a456', PasscodeKind.pin), isNotNull);
      expect(check('hunter', PasscodeKind.password), isNull);
      expect(check('short', PasscodeKind.password), isNotNull);
    });

    test('setup, unlock and lockout after repeated failures', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final auth = VaultAuthService();
      expect(await auth.config(), isNull);

      await auth.configure(
        method: VaultUnlockMethod.both,
        kind: PasscodeKind.pin,
        passcode: '482913',
      );
      final config = await auth.config();
      expect(config?.method, VaultUnlockMethod.both);
      expect(config?.passcodeKind, PasscodeKind.pin);

      expect(await auth.verifyPasscode('482913'), isA<PasscodeAccepted>());

      for (var i = 1; i < VaultAuthService.maxAttempts; i++) {
        final r = await auth.verifyPasscode('000000');
        expect(r, isA<PasscodeRejected>());
        expect(
          (r as PasscodeRejected).attemptsLeft,
          VaultAuthService.maxAttempts - i,
        );
      }
      final locked = await auth.verifyPasscode('000000');
      expect(locked, isA<PasscodeLockedOut>());
      // Even the right PIN is refused during the lockout.
      expect(await auth.verifyPasscode('482913'), isA<PasscodeLockedOut>());
      expect(await auth.lockoutRemaining(), isNotNull);

      await auth.reset();
      expect(await auth.config(), isNull);
    });

    test('switching to biometric-only removes the stored passcode', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final auth = VaultAuthService();
      await auth.configure(
        method: VaultUnlockMethod.passcode,
        kind: PasscodeKind.password,
        passcode: 'correct horse',
      );
      await auth.configure(method: VaultUnlockMethod.biometric);
      expect((await auth.config())?.passcodeKind, isNull);
      expect(
        await auth.verifyPasscode('correct horse'),
        isA<PasscodeRejected>(),
      );
    });
  });

  group('Persistence', () {
    test('activity log survives a restart and keeps newest first', () async {
      SharedPreferences.setMockInitialValues({});
      var container = ProviderContainer();
      await container.read(activityProvider.future);
      final notifier = container.read(activityProvider.notifier);
      await notifier.add(
        ActivityEntry.create(
          kind: ActivityKind.converted,
          name: 'a.jpg',
          sizeBytes: 1,
        ),
      );
      await notifier.add(
        ActivityEntry.create(
          kind: ActivityKind.received,
          name: 'b.pdf',
          sizeBytes: 2,
        ),
      );
      container.dispose();

      container = ProviderContainer();
      final entries = await container.read(activityProvider.future);
      expect(entries.map((e) => e.name), ['b.pdf', 'a.jpg']);
      expect(entries.first.kind, ActivityKind.received);
      container.dispose();
    });

    test('profile is saved trimmed', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      await container.read(profileProvider.future);
      await container
          .read(profileProvider.notifier)
          .save(const UserProfile(name: '  Ada Lovelace ', email: 'ada@x.io'));
      final profile = container.read(profileProvider).value!;
      expect(profile.name, 'Ada Lovelace');
      expect(profile.initials, 'AL');
      container.dispose();
    });
  });

  group('Storage overview', () {
    StorageSnapshot snap(MediaAccess access) => StorageSnapshot(
      capacity: const StorageCapacity(
        totalBytes: 100 << 30,
        freeBytes: 25 << 30,
      ),
      media: access == MediaAccess.full
          ? (
              images: const MediaUsage(bytes: 10 << 30, count: 900),
              videos: const MediaUsage(bytes: 20 << 30, count: 40),
              audio: const MediaUsage(bytes: 1 << 30, count: 300),
            )
          : null,
      access: access,
      app: const AppUsage(
        converted: 1 << 20,
        received: 2 << 20,
        vault: 3 << 20,
      ),
      takenAt: DateTime(2026, 1, 1, 9, 5),
    );

    for (final access in MediaAccess.values) {
      testWidgets('renders real figures with access: ${access.name}', (
        tester,
      ) async {
        var asked = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: StorageOverview(
                  snapshot: snap(access),
                  onRequestAccess: () => asked++,
                  onOpenSettings: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('25 GB'), findsOneWidget); // free
        expect(find.text('UPDATED 09:05'), findsOneWidget);
        if (access == MediaAccess.full) {
          expect(find.text('Images'), findsOneWidget);
          expect(find.text('System & other apps'), findsOneWidget);
        }
        if (access == MediaAccess.denied) {
          await tester.tap(find.text('Allow access'));
          expect(asked, 1);
        }
      });
    }
  });
}
