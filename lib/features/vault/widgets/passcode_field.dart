import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/features/vault/data/vault_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// PIN (6 digits, submits automatically) or password entry.
class PasscodeField extends StatefulWidget {
  const PasscodeField({
    super.key,
    required this.kind,
    required this.label,
    required this.onSubmitted,
    this.controller,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
  });

  final PasscodeKind kind;
  final String label;
  final ValueChanged<String> onSubmitted;
  final TextEditingController? controller;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final TextInputAction textInputAction;

  @override
  State<PasscodeField> createState() => _PasscodeFieldState();
}

class _PasscodeFieldState extends State<PasscodeField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pin = widget.kind == PasscodeKind.pin;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: !_visible,
      obscuringCharacter: '●',
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: pin ? TextInputType.number : TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      maxLength: pin ? 6 : 64,
      inputFormatters: pin ? [FilteringTextInputFormatter.digitsOnly] : null,
      textAlign: pin ? TextAlign.center : TextAlign.start,
      autofillHints: const [AutofillHints.password],
      style: pin
          ? AppType.mono.copyWith(fontSize: 24, letterSpacing: 12, color: p.ink)
          : Theme.of(context).textTheme.bodyLarge,
      onChanged: (v) {
        if (pin && v.length == 6) widget.onSubmitted(v);
      },
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        counterText: '',
        errorText: widget.errorText,
        errorMaxLines: 2,
        suffixIcon: IconButton(
          tooltip: _visible ? 'Hide' : 'Show',
          icon: Icon(
            _visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}
