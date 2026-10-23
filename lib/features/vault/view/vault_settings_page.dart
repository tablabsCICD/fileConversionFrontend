import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/features/vault/data/vault_auth_service.dart';
import 'package:file_convertor/features/vault/data/vault_repository.dart';
import 'package:file_convertor/features/vault/view/vault_lock_page.dart';
import 'package:file_convertor/features/vault/widgets/vault_setup_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Change how the vault unlocks, lock it, or erase it. Only reachable while
/// the vault is unlocked.
class VaultSettingsPage extends ConsumerStatefulWidget {
  const VaultSettingsPage({super.key, required this.onLockNow});

  final VoidCallback onLockNow;

  @override
  ConsumerState<VaultSettingsPage> createState() => _VaultSettingsPageState();
}

class _VaultSettingsPageState extends ConsumerState<VaultSettingsPage> {
  VaultConfig? _config;
  BiometricSupport? _bio;
  bool _changing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = ref.read(vaultAuthProvider);
    final config = await auth.config();
    final bio = await auth.biometricSupport();
    if (mounted) {
      setState(() {
        _config = config;
        _bio = bio;
      });
    }
  }

  String _describe(VaultConfig c) {
    final passcode = c.passcodeKind == PasscodeKind.password
        ? 'Password'
        : 'PIN';
    final bio = _bio?.label ?? 'Fingerprint';
    return switch (c.method) {
      VaultUnlockMethod.passcode => passcode,
      VaultUnlockMethod.biometric => '$bio only',
      VaultUnlockMethod.both => '$bio or $passcode',
    };
  }

  Future<void> _erase() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase the vault?'),
        content: const Text(
          'All vault files and your unlock method will be permanently deleted.',
        ),
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
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(vaultRepositoryProvider).wipe();
    await ref.read(vaultAuthProvider).reset();
    if (!mounted) return;
    Navigator.of(context)
      ..popUntil((r) => r.isFirst)
      ..push(MaterialPageRoute(builder: (_) => const VaultLockPage()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final gutter = AppSpace.gutter(MediaQuery.sizeOf(context).width);
    final config = _config;

    return Scaffold(
      appBar: AppBar(title: const Text('Vault settings')),
      body: config == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpace.sm,
                gutter,
                AppSpace.xxl,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _changing
                        ? VaultSetupFlow(
                            current: config,
                            submitLabel: 'Save',
                            onComplete: () {
                              setState(() => _changing = false);
                              _load();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unlock method updated'),
                                ),
                              );
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'UNLOCK METHOD',
                                style: AppType.eyebrow.copyWith(
                                  color: p.inkMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                _describe(config),
                                style: text.headlineMedium,
                              ),
                              const SizedBox(height: AppSpace.md),
                              AppButton(
                                label: 'Change unlock method',
                                icon: Icons.tune,
                                variant: AppButtonVariant.secondary,
                                onPressed: () =>
                                    setState(() => _changing = true),
                                expand: true,
                              ),
                              const SizedBox(height: AppSpace.sm),
                              AppButton(
                                label: 'Lock now',
                                icon: Icons.lock_outline,
                                variant: AppButtonVariant.secondary,
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onLockNow();
                                },
                                expand: true,
                              ),
                              const SizedBox(height: AppSpace.xl),
                              Divider(color: p.line),
                              const SizedBox(height: AppSpace.lg),
                              Text(
                                'DANGER ZONE',
                                style: AppType.eyebrow.copyWith(
                                  color: p.danger,
                                ),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              AppButton(
                                label: 'Erase vault',
                                icon: Icons.delete_forever_outlined,
                                variant: AppButtonVariant.danger,
                                onPressed: _erase,
                                expand: true,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
