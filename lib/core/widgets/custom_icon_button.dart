import 'package:flutter/material.dart';

/// A customizable icon button that follows Material Design guidelines.
///
/// This widget extends the functionality of [IconButton] by providing
/// more flexible theming options and better default values.
class CustomIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData iconData;
  final Color? iconColor;
  final double? iconSize;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final VisualDensity? visualDensity;
  final ButtonStyle? style;

  const CustomIconButton({
    super.key,
    required this.onPressed,
    required this.iconData,
    this.iconColor,
    this.iconSize,
    this.tooltip,
    this.padding = const EdgeInsets.all(12.0),
    this.constraints,
    this.visualDensity,
    this.style,
  });

  Color _determineIconColor(BuildContext context) {
    if (iconColor != null) return iconColor!;

    final theme = Theme.of(context);
    final iconButtonTheme = theme.iconButtonTheme;
    final overallIconTheme = IconTheme.of(context);

    return iconButtonTheme.style?.iconColor?.resolve({}) ??
        overallIconTheme.color ??
        _getAppBarIconColor(context) ??
        theme.colorScheme.onSurface;
  }

  Color? _getAppBarIconColor(BuildContext context) {
    final appBarTheme = AppBarTheme.of(context);
    return appBarTheme.actionsIconTheme?.color ?? appBarTheme.iconTheme?.color;
  }

  double _determineIconSize(BuildContext context) {
    final theme = Theme.of(context);
    final iconButtonTheme = theme.iconButtonTheme;
    final overallIconTheme = IconTheme.of(context);

    return iconSize ??
        iconButtonTheme.style?.iconSize?.resolve({}) ??
        overallIconTheme.size ??
        24.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconButtonTheme = theme.iconButtonTheme;

    return IconButton(
      icon: Icon(
        iconData,
        color: _determineIconColor(context),
        size: _determineIconSize(context),
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: padding,
      constraints: constraints,
      visualDensity: visualDensity,
      style: style ?? iconButtonTheme.style,
    );
  }
}
