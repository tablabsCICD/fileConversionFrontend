import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/features/vault/data/vault_auth_service.dart';
import 'package:file_convertor/features/vault/widgets/passcode_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The four ways a user can protect the vault.
enum _Choice {
  pin(
    'PIN',
    '6 digits',
    Icons.dialpad,
    VaultUnlockMethod.passcode,
    PasscodeKind.pin,
  ),
  password(
    'Password',
    'Letters, numbers, symbols',
    Icons.password,
    VaultUnlockMethod.passcode,
    PasscodeKind.password,
  ),
  biometric(
    'Fingerprint only',
    'Device screen lock as backup',
    Icons.fingerprint,
    VaultUnlockMethod.biometric,
    null,
  ),
  both(
    'Fingerprint + PIN or password',
    'Use whichever is handy',
    Icons.verified_user_outlined,
    VaultUnlockMethod.both,
    null,
  );

  const _Choice(this.title, this.subtitle, this.icon, this.method, this.kind);
  final String title;
  final String subtitle;
  final IconData icon;
  final VaultUnlockMethod method;
  final PasscodeKind? kind;
}

enum _Step { method, backupKind, create, confirm }

/// Choose an unlock method and (if needed) create a PIN/password.
/// Used for first-time setup and for changing the method later.
class VaultSetupFlow extends ConsumerStatefulWidget {
  const VaultSetupFlow({
    super.key,
    required this.onComplete,
    this.current,
    this.submitLabel = 'Secure vault',
  });

  /// Called after the new configuration is saved.
  final VoidCallback onComplete;

  /// The existing configuration, when changing it.
  final VaultConfig? current;
  final String submitLabel;

  @override
  ConsumerState<VaultSetupFlow> createState() => _VaultSetupFlowState();
}

class _VaultSetupFlowState extends ConsumerState<VaultSetupFlow> {
  _Step _step = _Step.method;
  _Choice? _choice;
  PasscodeKind _kind = PasscodeKind.pin;
  String _first = '';
  String? _error;
  bool _busy = false;
  BiometricSupport? _bio;
  final _createController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(vaultAuthProvider).biometricSupport().then((s) {
      if (mounted) setState(() => _bio = s);
    });
  }

  @override
  void dispose() {
    _createController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _choiceEnabled(_Choice c) =>
      !c.method.usesBiometric || (_bio?.available ?? false);

  Future<void> _pick(_Choice c) async {
    setState(() {
      _choice = c;
      _error = null;
    });
    if (c.method.usesBiometric) {
      // Confirm the sensor works before relying on it.
      setState(() => _busy = true);
      final error = await ref.read(vaultAuthProvider).authenticateBiometric();
      if (!mounted) return;
      setState(() => _busy = false);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      if (c == _Choice.biometric) return _save();
      setState(() => _step = _Step.backupKind);
      return;
    }
    setState(() {
      _kind = c.kind!;
      _step = _Step.create;
    });
  }

  void _create(String value) {
    final problem = VaultAuthService.validatePasscode(value, _kind);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _first = value;
      _error = null;
      _step = _Step.confirm;
    });
  }

  void _confirm(String value) {
    if (value != _first) {
      _confirmController.clear();
      setState(() => _error = 'Doesn’t match. Try again.');
      return;
    }
    _save(passcode: value);
  }

  Future<void> _save({String? passcode}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(vaultAuthProvider)
          .configure(
            method: _choice!.method,
            kind: _choice!.method.usesPasscode ? _kind : null,
            passcode: passcode,
          );
      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() => setState(() {
    _error = null;
    _confirmController.clear();
    if (_step == _Step.confirm) _createController.clear();
    _step = switch (_step) {
      _Step.confirm => _Step.create,
      _Step.create when _choice == _Choice.both => _Step.backupKind,
      _ => _Step.method,
    };
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.base),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: switch (_step) {
          _Step.method => _methodStep(context),
          _Step.backupKind => _backupStep(context),
          _Step.create => _passcodeStep(
            context,
            title: _kind == PasscodeKind.pin
                ? 'Create a PIN'
                : 'Create a password',
            hint: _kind == PasscodeKind.pin
                ? 'Choose 6 digits. Avoid birthdays and 123456.'
                : 'At least 6 characters.',
            field: PasscodeField(
              key: const ValueKey('create'),
              kind: _kind,
              controller: _createController,
              label: _kind == PasscodeKind.pin ? 'New PIN' : 'New password',
              autofocus: true,
              errorText: _error,
              onSubmitted: _create,
            ),
          ),
          _Step.confirm => _passcodeStep(
            context,
            title: 'Confirm it',
            hint: 'Enter it once more.',
            field: PasscodeField(
              key: const ValueKey('confirm'),
              kind: _kind,
              controller: _confirmController,
              label: _kind == PasscodeKind.pin
                  ? 'Confirm PIN'
                  : 'Confirm password',
              autofocus: true,
              errorText: _error,
              enabled: !_busy,
              onSubmitted: _confirm,
            ),
          ),
        },
      ),
    );
  }

  Widget _methodStep(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bio = _bio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('How should it unlock?', style: text.headlineMedium),
        const SizedBox(height: AppSpace.xs),
        Text(
          'You can change this later in vault settings.',
          style: text.bodyMedium?.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: AppSpace.lg),
        for (final c in _Choice.values) ...[
          _ChoiceTile(
            choice: c,
            title: c.method.usesBiometric && bio != null && bio.available
                ? c.title.replaceFirst('Fingerprint', bio.label)
                : c.title,
            enabled: _choiceEnabled(c) && !_busy,
            selected:
                widget.current?.method == c.method &&
                (c.kind == null || widget.current?.passcodeKind == c.kind),
            busy: _busy && _choice == c,
            onTap: () => _pick(c),
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        if (bio != null && !bio.available) ...[
          const SizedBox(height: AppSpace.xs),
          InlineNotice(
            title: 'Fingerprint unlock unavailable',
            message: bio.reason,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.sm),
          InlineNotice(tone: NoticeTone.danger, title: _error!),
        ],
      ],
    );
  }

  Widget _backupStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Add a backup', style: text.headlineMedium),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Use it when your finger or face isn’t recognised.',
          style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
        ),
        const SizedBox(height: AppSpace.lg),
        for (final c in [_Choice.pin, _Choice.password]) ...[
          _ChoiceTile(
            choice: c,
            title: c.title,
            enabled: true,
            onTap: () => setState(() {
              _kind = c.kind!;
              _step = _Step.create;
            }),
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'Back',
            icon: Icons.arrow_back,
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: _back,
          ),
        ),
      ],
    );
  }

  Widget _passcodeStep(
    BuildContext context, {
    required String title,
    required String hint,
    required Widget field,
  }) {
    final text = Theme.of(context).textTheme;
    final pin = _kind == PasscodeKind.pin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: text.headlineMedium),
        const SizedBox(height: AppSpace.xs),
        Text(
          hint,
          style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
        ),
        const SizedBox(height: AppSpace.lg),
        field,
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            AppButton(
              label: 'Back',
              icon: Icons.arrow_back,
              variant: AppButtonVariant.ghost,
              onPressed: _busy ? null : _back,
            ),
            const Spacer(),
            if (!pin)
              AppButton(
                label: _step == _Step.confirm ? widget.submitLabel : 'Continue',
                isLoading: _busy,
                onPressed: () => _step == _Step.confirm
                    ? _confirm(_confirmController.text)
                    : _create(_createController.text),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.title,
    required this.enabled,
    required this.onTap,
    this.selected = false,
    this.busy = false,
  });

  final _Choice choice;
  final String title;
  final bool enabled;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(
          color: selected ? p.accent : p.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md - 2),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: enabled ? p.accentSoft : p.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  choice.icon,
                  size: 20,
                  color: enabled ? p.accent : p.inkFaint,
                ),
              ),
              const SizedBox(width: AppSpace.md - 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        color: enabled ? p.ink : p.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected
                          ? 'CURRENT · ${choice.subtitle}'
                          : choice.subtitle,
                      style: AppType.mono.copyWith(
                        color: p.inkMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: enabled ? p.inkMuted : p.inkFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
