import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final String? semanticLabel;

  const CustomText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyLarge;

    final effectiveStyle = (defaultStyle ?? const TextStyle()).merge(style);

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      semanticsLabel: semanticLabel,
    );
  }
}
