import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable text field widget that wraps Flutter's TextFormField with
/// additional styling and functionality.
class CustomTextField extends StatelessWidget {
  // Text field controller and content
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final TextStyle? style;

  // Icons and decoration
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final InputDecoration? decoration;
  final VoidCallback? onSuffixIconTap;

  // Text field behavior
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  // Validation and formatting
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  // Callbacks
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.onSuffixIconTap,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      decoration: _buildDecoration(context),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      style: _buildTextStyle(theme),
    );
  }

  /// Builds the text field decoration with proper theming and styling.
  InputDecoration _buildDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final defaultDecoration = InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      suffixIcon: suffixIcon != null
          ? IconButton(
              onPressed: onSuffixIconTap,
              icon: Icon(
                suffixIcon,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
    );

    return (decoration ?? defaultDecoration)
        .applyDefaults(theme.inputDecorationTheme)
        .copyWith(
          labelText: labelText,
          hintText: hintText,
        );
  }

  /// Builds the text style by merging theme style with custom style.
  TextStyle _buildTextStyle(ThemeData theme) {
    final themeTextStyle = theme.textTheme.bodyLarge;
    return (themeTextStyle ?? const TextStyle()).merge(style);
  }
}
