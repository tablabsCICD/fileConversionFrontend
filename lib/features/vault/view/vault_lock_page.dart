import 'dart:async';

import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/features/vault/data/vault_auth_service.dart';
import 'package:file_convertor/features/vault/data/vault_repository.dart';
import 'package:file_convertor/features/vault/widgets/passcode_field.dart';
import 'package:file_convertor/features/vault/widgets/vault_setup_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vault_page.dart';

/// Entry point to the Private Vault: first-run setup, then unlock with the
/// method the user chose (PIN, password, biometrics, or biometrics + backup).
class VaultLockPage extends ConsumerStatefulWidget {
  const VaultLockPage({super.key});

  @override
  ConsumerState<VaultLockPage> createState() => _VaultLockPageState();
}

enum _Mode { loading, intro, setup, unlock }

class _VaultLockPageState extends ConsumerState<VaultLockPage> {
  _Mode _mode = _Mode.loading;
  VaultConfig? _config;
  BiometricSupport _bio = BiometricSupport.none;

  final _passcode = TextEditingController();
  String? _error;
  bool _busy = false;
  Duration? _lockedFor;
  Timer? _lockTimer;

  VaultAuthService get _auth => ref.read(vaultAuthProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _passcode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await _auth.config();
    final bio = await _auth.biometricSupport();
    final locked = await _auth.lockoutRemaining();
    if (!mounted) return;
    setState(() {
      _config = config;
      _bio = bio;
      _mode = config == null ? _Mode.intro : _Mode.unlock;
    });
    if (locked != null) _startLockout(locked);
    if (config != null && config.method.usesBiometric && bio.available) {
      // Offer biometrics straight away; the user can cancel to type instead.
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    }
  }

  void _startLockout(Duration d) {
    _lockTimer?.cancel();
    setState(() => _lockedFor = d);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = (_lockedFor ?? Duration.zero) - const Duration(seconds: 1);
      if (!mounted) return t.cancel();
      if (left <= Duration.zero) {
        t.cancel();
        setState(() {
          _lockedFor = null;
          _error = null;
        });
      } else {
        setState(() => _lockedFor = left);
      }
    });
  }

  Future<void> _submitPasscode(String value) async {
    if (_busy || _lockedFor != null || value.isEmpty) return;
    setState(() => _busy = true);
    final result = await _auth.verifyPasscode(value);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case PasscodeAccepted():
        _openVault();
      case PasscodeRejected(:final attemptsLeft):
        _passcode.clear();
        setState(() {
          _error = attemptsLeft <= 2
              ? 'Incorrect. $attemptsLeft ${attemptsLeft == 1 ? 'attempt' : 'attempts'} '
                    'left before a short lockout.'
              : 'Incorrect. Try again.';
        });
      case PasscodeLockedOut(:final wait):
        _passcode.clear();
        setState(() => _error = 'Too many attempts.');
        _startLockout(wait);
    }
  }

  Future<void> _biometric({bool deviceCredential = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.authenticateBiometric(
      allowDeviceCredential: deviceCredential,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      _openVault();
    } else if (error != 'Authentication was cancelled.') {
      setState(() => _error = error);
    }
  }

  void _openVault() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VaultPage()),
    );
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset the vault?'),
        content: const Text(
          'Every file in the vault will be permanently deleted. Your unlock '
          'method will be removed so you can set it up again.',
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
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(vaultRepositoryProvider).wipe();
    await _auth.reset();
    if (!mounted) return;
    _lockTimer?.cancel();
    setState(() {
      _config = null;
      _lockedFor = null;
      _error = null;
      _mode = _Mode.intro;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'PRIVATE VAULT',
          style: AppType.eyebrow.copyWith(color: p.inkMuted),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg - 4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(AppSpace.lg + 4),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: AppRadius.sheet,
                  border: Border.all(color: p.line),
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.base),
                  child: KeyedSubtree(
                    key: ValueKey(_mode),
                    child: switch (_mode) {
                      _Mode.loading => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      _Mode.intro => _intro(context),
                      _Mode.setup => VaultSetupFlow(onComplete: _openVault),
                      _Mode.unlock => _unlock(context),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _VaultMark(),
        const SizedBox(height: AppSpace.lg),
        Text("Private Vault", style: text.headlineLarge),
        const SizedBox(height: AppSpace.md),
        const _Feature(
          Icons.enhanced_encryption_outlined,
          "Files are encrypted with AES-256 on this device",
        ),
        _Feature(
          Icons.fingerprint,
          _bio.available
              ? "Unlock with ${_bio.label.toLowerCase()}, a PIN or a password"
              : "Unlock with a PIN or a password",
        ),
        const _Feature(
          Icons.visibility_off_outlined,
          "Kept out of your gallery and Files app",
        ),
        const _Feature(
          Icons.lock_clock_outlined,
          "Locks itself when you leave the app",
        ),
        const SizedBox(height: AppSpace.xl),
        AppButton(
          label: "Set up vault",
          trailingIcon: Icons.arrow_forward,
          onPressed: () => setState(() => _mode = _Mode.setup),
          size: AppButtonSize.large,
          expand: true,
        ),
      ],
    );
  }

  Widget _unlock(BuildContext context) {
    final config = _config!;
    final text = Theme.of(context).textTheme;
    final locked = _lockedFor;
    final kind = config.passcodeKind ?? PasscodeKind.pin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: _VaultMark()),
        const SizedBox(height: AppSpace.lg - 4),
        Text("Unlock Vault", style: text.headlineLarge),
        const SizedBox(height: AppSpace.lg),
        if (config.method.usesBiometric) ...[
          AppButton(
            label: _bio.available
                ? 'Unlock with ${_bio.label}'
                : 'Unlock with fingerprint',
            icon: _bio.hasFace && !_bio.hasFingerprint
                ? Icons.face_outlined
                : Icons.fingerprint,
            isLoading: _busy && !config.method.usesPasscode,
            onPressed: _bio.available ? () => _biometric() : null,
            size: AppButtonSize.large,
            expand: true,
          ),
          if (!_bio.available) ...[
            const SizedBox(height: AppSpace.sm),
            InlineNotice(
              tone: NoticeTone.warning,
              title: 'Biometrics unavailable right now',
              message: _bio.reason,
            ),
          ],
        ],
        if (config.method == VaultUnlockMethod.both) ...[
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Text(
                  kind == PasscodeKind.pin
                      ? 'OR USE YOUR PIN'
                      : 'OR USE YOUR PASSWORD',
                  style: AppType.eyebrow.copyWith(
                    color: context.palette.inkMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpace.md),
        ],
        if (config.method.usesPasscode) ...[
          PasscodeField(
            kind: kind,
            controller: _passcode,
            label: kind == PasscodeKind.pin ? 'PIN' : 'Password',
            enabled: locked == null && !_busy,
            autofocus: !config.method.usesBiometric,
            errorText: locked != null
                ? 'Too many attempts. Try again in ${_format(locked)}.'
                : _error,
            onSubmitted: _submitPasscode,
          ),
          if (kind == PasscodeKind.password) ...[
            const SizedBox(height: AppSpace.md),
            AppButton(
              label: 'Unlock',
              isLoading: _busy,
              onPressed: locked == null
                  ? () => _submitPasscode(_passcode.text)
                  : null,
              size: AppButtonSize.large,
              expand: true,
            ),
          ],
        ] else if (_error != null) ...[
          const SizedBox(height: AppSpace.sm),
          InlineNotice(tone: NoticeTone.danger, title: _error!),
        ],
        if (config.method == VaultUnlockMethod.biometric) ...[
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: 'Use device screen lock',
            variant: AppButtonVariant.secondary,
            onPressed: () => _biometric(deviceCredential: true),
            expand: true,
          ),
        ],
        const SizedBox(height: AppSpace.md),
        Align(
          child: AppButton(
            label: config.method.usesPasscode
                ? 'Forgot ${kind == PasscodeKind.pin ? 'PIN' : 'password'}?'
                : 'Can’t unlock?',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: _confirmReset,
          ),
        ),
      ],
    );
  }

  static String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s.toString().padLeft(2, '0')}s' : '${s}s';
  }
}

class _VaultMark extends StatelessWidget {
  const _VaultMark();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
      ),
      child: Icon(Icons.lock_outline, size: 26, color: p.paper),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: p.accent),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
