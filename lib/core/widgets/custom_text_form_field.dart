import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;

  /// Texts
  final String? labelText;
  final String hintText;

  /// Behaviour
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  /// UI
  final Widget? prefix;
  final Widget? suffix;

  /// Callbacks
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focused != _focusNode.hasFocus) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;

    final borderColor = !widget.enabled
        ? p.line
        : _focused
        ? p.accent
        : p.lineStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// OPTIONAL LABEL
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: AppSpace.xs - 2),
            child: Text(
              widget.labelText!,
              style: theme.textTheme.labelMedium?.copyWith(color: p.inkMuted),
            ),
          ),
        ],

        /// FIELD CONTAINER
        AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          constraints: const BoxConstraints(minHeight: AppSize.field),
          decoration: BoxDecoration(
            color: widget.enabled ? p.surface : p.surfaceSunken,
            borderRadius: AppRadius.control,
            border: Border.all(color: borderColor, width: _focused ? 2 : 1),
          ),
          // Keep the text from shifting when the border thickens.
          padding: EdgeInsets.symmetric(horizontal: _focused ? 13 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.prefix != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: _focused ? p.accent : p.inkMuted,
                    size: 20,
                  ),
                  child: widget.prefix!,
                ),
                const SizedBox(width: AppSpace.sm - 2),
              ],

              /// TEXT FIELD
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  enabled: widget.enabled,
                  maxLines: widget.maxLines,
                  validator: widget.validator,
                  onChanged: widget.onChanged,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  cursorColor: p.accent,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: p.inkMuted,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpace.md - 1,
                    ),
                  ),
                ),
              ),

              if (widget.suffix != null) ...[
                const SizedBox(width: AppSpace.sm - 2),
                IconTheme(
                  data: IconThemeData(color: p.inkMuted, size: 20),
                  child: widget.suffix!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
