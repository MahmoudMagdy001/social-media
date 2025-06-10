import 'package:flutter/material.dart';

import 'custom_icon_button.dart';
import 'custom_text.dart';

/// A custom app bar widget that displays the Facebook logo and action buttons.
class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppbar({
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      title: CustomText(
        'dodybook',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        CustomIconButton(
          onPressed: () {},
          iconData: Icons.search,
          iconSize: 24,
        ),
        const SizedBox(width: 8),
        CustomIconButton(
          onPressed: () {},
          iconData: Icons.message,
          iconSize: 24,
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 16),
      ],
    );
  }
}
