import 'package:cached_network_image/cached_network_image.dart';
import 'package:facebook_clone/screens/menu/account_setting.dart'; // Ensure this path is correct
import 'package:facebook_clone/screens/menu/profile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../main.dart'; // Ensure this path is correct
import '../../services/auth_services/auth_service.dart'; // Ensure this path is correct
import '../../widgets/custom_text.dart'; // Ensure this path is correct
import '../Auth/login_screen.dart'; // Ensure this path is correct

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
  final supabase.User? _currentUser =
      supabase.Supabase.instance.client.auth.currentUser;

  String? _currentProfileImage;
  String? _currentDisplayName;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (_currentUser == null) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
      debugPrint("MenuScreen: No current user found.");
      return;
    }

    try {
      final userData = await supabase.Supabase.instance.client
          .from('users')
          .select('display_name, email, profile_image')
          .eq('id', _currentUser!.id)
          .single();

      if (mounted) {
        setState(() {
          _currentDisplayName = userData['display_name'] as String? ?? '';
          _currentProfileImage = userData['profile_image'] as String?;
          _isLoadingProfile = false;
          debugPrint('currentProfileImage: $_currentProfileImage');
          debugPrint('currentDisplayName: $_currentDisplayName');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText('Error loading profile data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint("Error fetching user profile: ${e.toString()}");
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await widget.authService.signOut();
      if (mounted) {
        Navigator.of(context).pop(); // Pops the dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(authService: widget.authService),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
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

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(authService: widget.authService),
      ),
    );
  }

  void _navigateToUserProfile() {
    if (_currentUser != null &&
        _currentDisplayName != null &&
        _currentProfileImage != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => UserProfile(
          displayName: _currentDisplayName!,
          imageUrl: _currentProfileImage!,
          email: _currentUser!.email!,
        ),
      ));
    }
  }

  void _navigateToAccountSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AccountSetting(),
    ));
  }

  void _handleThemeChange(bool isDarkMode) {
    MyApp.of(context)
        ?.changeTheme(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  void _showPrivacyPolicySnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View Privacy Policy (Not Implemented)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile && _currentUser != null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return _buildLoggedOutView();
    }

    return _buildLoggedInView();
  }

  Widget _buildLoggedOutView() {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu")), // Added a title for context
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("You are not logged in."),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToLogin,
              child: const Text("Go to Login"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sectionHeaderColor = _getSectionHeaderColor(context, isDarkMode);

    return Scaffold(
      // appBar: AppBar(title: Text(_currentDisplayName ?? "Menu")), // Optional: Show user name or "Menu"
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _ProfileSection(
            displayName: _currentDisplayName,
            email: _currentUser?.email,
            profileImageUrl: _currentProfileImage,
            onTap: _navigateToUserProfile,
          ),
          const Divider(),
          _MenuSectionHeader(title: 'General', color: sectionHeaderColor),
          _MenuItemTile(
            icon: Icons.account_circle,
            title: 'Account Settings',
            subtitle: 'Manage your account details',
            onTap: _navigateToAccountSettings,
          ),
          const Divider(),
          _AppearanceSection(
            sectionHeaderColor: sectionHeaderColor,
            isDarkMode: isDarkMode,
            onThemeChanged: _handleThemeChange,
          ),
          const Divider(),
          _AboutSection(
            sectionHeaderColor: sectionHeaderColor,
            onPrivacyPolicyTap: _showPrivacyPolicySnackbar,
          ),
          const Divider(),
          _MenuItemTile(
            icon: Icons.logout,
            title: 'Logout',
            titleColor: Colors.red[700],
            iconColor: Colors.red[700],
            onTap: _handleLogout,
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
