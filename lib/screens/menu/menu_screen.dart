import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/widgets/custom_text.dart';
import '../../features/layout/model/layout_model.dart';
import '../../features/signin/view/signin_view.dart';
import '../../main.dart';
import 'account_setting.dart';
import 'privacy_policy_screen.dart';
import 'profile.dart';

class MenuScreen extends StatelessWidget {
  final UserModel user;
  const MenuScreen({
    super.key,
    required this.user,
  });

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      supabase.Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pop(); // Pops the dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => SigninView(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint("Error during logout: ${e.toString()}");
    }
  }

  void _navigateToUserProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => UserProfile(
        displayName: user.displayName,
        imageUrl: user.profileImage,
        userId: user.id,
        currentUserId: user.id,
      ),
    ));
  }

  void _navigateToAccountSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AccountSetting(),
    ));
  }

  void _handleThemeChange(BuildContext context, bool isDarkMode) {
    MyApp.of(context)
        ?.changeTheme(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return _buildLoggedInView(context);
  }

  Widget _buildLoggedInView(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sectionHeaderColor = _getSectionHeaderColor(context, isDarkMode);

    return Scaffold(
      // appBar: AppBar(title: Text(_currentDisplayName ?? "Menu")), // Optional: Show user name or "Menu"
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _ProfileSection(
            displayName: user.displayName,
            email: user.email,
            profileImageUrl: user.profileImage,
            onTap: () {
              _navigateToUserProfile(context);
            },
          ),
          const Divider(),
          _MenuSectionHeader(title: 'General', color: sectionHeaderColor),
          _MenuItemTile(
            icon: Icons.account_circle,
            title: 'Account Settings',
            subtitle: 'Manage your account details',
            onTap: () {
              _navigateToAccountSettings(context);
            },
          ),
          const Divider(),
          _AppearanceSection(
            sectionHeaderColor: sectionHeaderColor,
            isDarkMode: isDarkMode,
            onThemeChanged: (bool value) {
              _handleThemeChange(context, value);
            },
          ),
          const Divider(),
          _AboutSection(
            sectionHeaderColor: sectionHeaderColor,
            onPrivacyPolicyTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return PrivacyPolicyScreen();
                  },
                ),
              );
            },
          ),
          const Divider(),
          _MenuItemTile(
            icon: Icons.logout,
            title: 'Logout',
            titleColor: Colors.red[700],
            iconColor: Colors.red[700],
            onTap: () {
              _handleLogout(context);
            },
          ),
          const SizedBox(height: 20), // Added some padding at the bottom
        ],
      ),
    );
  }

  Color _getSectionHeaderColor(BuildContext context, bool isDarkMode) {
    return Theme.of(context).textTheme.titleMedium?.color ??
        (isDarkMode ? Colors.tealAccent : Colors.blueAccent);
  }
}

// --- Extracted Widgets ---

class _MenuSectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _MenuSectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: CustomText(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
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
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: CustomText(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? CustomText(subtitle!) : null,
      trailing: (title != 'Logout') // Avoid arrow for logout
          ? const Icon(Icons.arrow_forward_ios)
          : null,
      onTap: onTap,
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  final Color sectionHeaderColor;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const _AppearanceSection({
    required this.sectionHeaderColor,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MenuSectionHeader(title: 'Appearance', color: sectionHeaderColor),
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
  final Color sectionHeaderColor;
  final VoidCallback onPrivacyPolicyTap;

  const _AboutSection({
    required this.sectionHeaderColor,
    required this.onPrivacyPolicyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MenuSectionHeader(title: 'About', color: sectionHeaderColor),
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
