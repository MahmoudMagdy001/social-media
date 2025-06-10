import 'package:facebook_clone/screens/menu/account_setting.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/auth_services/auth_service.dart';
import '../../widgets/custom_text.dart';
import '../Auth/login_screen.dart';

class MenuScreen extends StatefulWidget {
  final AuthService authService;

  const MenuScreen({
    super.key,
    required this.authService,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sectionHeaderColor = _getSectionHeaderColor(context, isDarkMode);

    return Scaffold(
      body: ListView(
        children: [
          _buildGeneralSection(sectionHeaderColor),
          _buildAccountSettingsTile(),
          const Divider(),
          _buildAppearanceSection(sectionHeaderColor, isDarkMode),
          const Divider(),
          _buildAboutSection(sectionHeaderColor),
          const Divider(),
          _buildLogoutTile(),
        ],
      ),
    );
  }

  Color _getSectionHeaderColor(BuildContext context, bool isDarkMode) {
    return Theme.of(context).textTheme.titleMedium?.color ??
        (isDarkMode ? Colors.tealAccent : Colors.blueAccent);
  }

  Widget _buildGeneralSection(Color sectionHeaderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: CustomText(
        'General',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: sectionHeaderColor,
        ),
      ),
    );
  }

  Widget _buildAccountSettingsTile() {
    return ListTile(
      leading: const Icon(Icons.account_circle),
      title: const CustomText('Account Settings'),
      subtitle: const CustomText('Manage your account details'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return AccountSetting();
          },
        ));
      },
    );
  }

  Widget _buildAppearanceSection(Color sectionHeaderColor, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: CustomText(
            'Appearance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: sectionHeaderColor,
            ),
          ),
        ),
        SwitchListTile(
          title: const CustomText('Dark Mode'),
          subtitle: CustomText(isDarkMode ? 'Enabled' : 'Disabled'),
          value: isDarkMode,
          onChanged: _handleThemeChange,
          secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
        ),
      ],
    );
  }

  void _handleThemeChange(bool value) {
    MyApp.of(context)?.changeTheme(
      value ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Widget _buildAboutSection(Color sectionHeaderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: CustomText(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: sectionHeaderColor,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const CustomText('App Version'),
          subtitle: const CustomText('1.0.0'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.policy),
          title: const CustomText('Privacy Policy'),
          onTap: _showPrivacyPolicySnackbar,
        ),
      ],
    );
  }

  void _showPrivacyPolicySnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: CustomText('View Privacy Policy (Not Implemented)'),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.red[700]),
      title: CustomText(
        'Logout',
        style: TextStyle(color: Colors.red[700]),
      ),
      onTap: _handleLogout,
    );
  }

  Future<void> _handleLogout() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await widget.authService.signOut();
      if (mounted) {
        // Pop the loading dialog
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(authService: widget.authService),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Pop the loading dialog
        Navigator.of(context).pop();
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
