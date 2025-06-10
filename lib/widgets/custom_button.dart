import 'package:flutter/material.dart';

/// A customizable button widget that follows Material Design guidelines.
///
/// This widget provides a consistent button style with support for:
/// - Custom text and icon
/// - Custom styling through ButtonStyle
/// - Custom text styling
/// - State-based color changes
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final ButtonStyle? style;
  final TextStyle? textStyle;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.style,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle = _getEffectiveStyle(context);
    final labelTextStyle = _getLabelTextStyle(theme, effectiveStyle);

    return ElevatedButton(
      onPressed: onPressed,
      style: effectiveStyle,
      child: _buildButtonContent(labelTextStyle, effectiveStyle),
    );
  }

  /// Builds the button content including icon and text
  Widget _buildButtonContent(
      TextStyle? labelTextStyle, ButtonStyle effectiveStyle) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(
              color: effectiveStyle.foregroundColor?.resolve({}),
            ),
            child: icon!,
          ),
          const SizedBox(width: 8),
        ],
        Text(text, style: labelTextStyle),
      ],
    );
  }

  /// Resolves the effective button style by merging theme and custom styles
  ButtonStyle _getEffectiveStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeButtonStyle = theme.elevatedButtonTheme.style;

    final defaultStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withAlpha(222);
        } else if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withAlpha(12);
        }
        return colorScheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withAlpha(51);
        }
        return colorScheme.onPrimary;
      }),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      elevation: WidgetStateProperty.resolveWith<double?>((states) {
        if (states.contains(WidgetState.pressed)) return 2.0;
        if (states.contains(WidgetState.disabled)) return 0.0;
        return 2.0;
      }),
      minimumSize:
          const WidgetStatePropertyAll<Size>(Size(double.infinity, 48)),
    );

    return (themeButtonStyle ?? const ButtonStyle())
        .merge(defaultStyle)
        .merge(style);
  }

  /// Resolves the effective text style for the button label
  TextStyle? _getLabelTextStyle(ThemeData theme, ButtonStyle effectiveStyle) {
    if (textStyle != null) return textStyle;

    final styleTextStyleProp = effectiveStyle.textStyle;
    if (styleTextStyleProp is WidgetStatePropertyAll<TextStyle?>) {
      return styleTextStyleProp.value;
    } else if (styleTextStyleProp != null) {
      return styleTextStyleProp.resolve({});
    }

    return theme.textTheme.labelLarge;
  }
}
