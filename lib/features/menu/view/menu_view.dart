import 'package:cached_network_image/cached_network_image.dart';
import 'package:facebook_clone/features/account_setting/view/account_setting_view.dart';
import 'package:facebook_clone/features/menu/view/widgets/privacy_view.dart';
import 'package:facebook_clone/features/menu/viewmodel/menu_cubit.dart';
import 'package:facebook_clone/features/profile/view/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/custom_text.dart';
import '../../layout/model/layout_model.dart';
import '../../signin/view/signin_view.dart';
import '../viewmodel/menu_state.dart';
import '../viewmodel/theme_cubit.dart';

class MenuView extends StatelessWidget {
  final UserModel currentUser;
  const MenuView({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => MenuCubit(),
        child: BlocBuilder<MenuCubit, MenuState>(
          builder: (context, state) {
            final cubit = context.read<MenuCubit>();
            return Scaffold(
              body: ListView(
                children: [
                  const SizedBox(height: 20),
                  // Profile
                  _ProfileSection(
                    displayName: currentUser.displayName,
                    email: currentUser.email,
                    profileImageUrl: currentUser.profileImage,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => UserProfileView(
                          currentUser: currentUser,
                          userId: currentUser.id,
                          displayName: currentUser.displayName,
                          profileImage: currentUser.profileImage,
                        ),
                      ));
                    },
                  ),
                  const Divider(),
                  // Account Settings
                  _MenuItemTile(
                    icon: Icons.account_circle,
                    title: 'Account Settings',
                    subtitle: 'Manage your account details',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            AccountSettingView(user: currentUser),
                      ));
                    },
                  ),
                  const Divider(),
                  // Theme
                  _AppearanceSection(
                    onThemeChanged: (bool value) {
                      context.read<ThemeCubit>().changeTheme(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                  const Divider(),
                  // About
                  _AboutSection(
                    onPrivacyPolicyTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return PrivacyView();
                          },
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  // logout
                  _MenuItemTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: Colors.red[700],
                    iconColor: Colors.red[700],
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          bool isLoggingOut = false;

                          return StatefulBuilder(
                            builder: (context, setState) => AlertDialog(
                              title: const Text('Logout'),
                              content: isLoggingOut
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Logging out...'),
                                      ],
                                    )
                                  : const Text(
                                      'Are you sure you want to logout?'),
                              actions: isLoggingOut
                                  ? []
                                  : [
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      TextButton(
                                        child: const Text(
                                          'Logout',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () async {
                                          setState(() {
                                            isLoggingOut = true;
                                          });

                                          await cubit.signOut(context);

                                          if (context.mounted) {
                                            Navigator.of(context)
                                                .pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const SigninView()),
                                              (route) => false,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(
                      height: 20), // Added some padding at the bottom
                ],
              ),
            );
          },
        ));
  }
}

// --- Extracted Widgets ---

class _MenuSectionHeader extends StatelessWidget {
  final String title;

  const _MenuSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: CustomText(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String? displayName;
  final String? email;
  final String? profileImageUrl;
  final VoidCallback onTap;

  const _ProfileSection({
    this.displayName,
    this.email,
    this.profileImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? profileImageProvider;
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      profileImageProvider = CachedNetworkImageProvider(profileImageUrl!);
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.grey[200],
        backgroundImage: profileImageProvider,
        child: profileImageProvider == null
            ? Icon(Icons.person, size: 35, color: Colors.grey[600])
            : null,
      ),
      title: Text(displayName ?? 'User Profile'),
      subtitle: email != null ? Text(email!) : null,
      onTap: onTap,
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor; // Added for logout tile customization

  const _MenuItemTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: CustomText(title, style: TextStyle(color: titleColor)),
          subtitle: subtitle != null ? CustomText(subtitle!) : null,
          trailing: (title != 'Logout') // Avoid arrow for logout
              ? const Icon(Icons.arrow_forward_ios)
              : null,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  final ValueChanged<bool> onThemeChanged;

  const _AppearanceSection({
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MenuSectionHeader(title: 'Appearance'),
        SwitchListTile(
          title: const CustomText('Dark Mode'),
          subtitle: CustomText(isDarkMode ? 'Enabled' : 'Disabled'),
          value: isDarkMode,
          onChanged: onThemeChanged,
          // Pass the callback directly
          secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  final VoidCallback onPrivacyPolicyTap;

  const _AboutSection({
    required this.onPrivacyPolicyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MenuSectionHeader(title: 'About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const CustomText('App Version'),
          subtitle: const CustomText('1.0.0'),
          onTap: () {
            // Could show an About Dialog
          },
        ),
        ListTile(
          leading: const Icon(Icons.policy),
          title: const CustomText('Privacy Policy'),
          onTap: onPrivacyPolicyTap,
        ),
      ],
    );
  }
}
