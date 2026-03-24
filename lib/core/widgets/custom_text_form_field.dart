import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
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
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// OPTIONAL LABEL (iOS Settings style)
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            child: Text(
              labelText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.canvasColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        /// FIELD CONTAINER
        Container(
          height: 50, // ✅ Standard iOS / Material height
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? theme.canvasColor.withOpacity(0.2)
                  : theme.canvasColor.withOpacity(0.05),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (prefix != null) ...[
                IconTheme(
                  data: IconThemeData(color: theme.primaryColor, size: 20),
                  child: prefix!,
                ),
                const SizedBox(width: 10),
              ],

              /// TEXT FIELD
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  enabled: enabled,
                  maxLines: maxLines,
                  validator: validator,
                  onChanged: onChanged,
                  textCapitalization: textCapitalization,
                  cursorColor: colorScheme.primary,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.canvasColor.withOpacity(0.75),
                    ),

                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              if (suffix != null) ...[
                const SizedBox(width: 10),
                IconTheme(
                  data: IconThemeData(
                    color: theme.canvasColor.withOpacity(0.75),
                    size: 20,
                  ),
                  child: suffix!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
