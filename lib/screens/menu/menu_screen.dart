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
  // currentUser can be null if no user is logged in, handle this possibility
  final supabase.User? currentUser =
      supabase.Supabase.instance.client.auth.currentUser;

  String? currentProfileImage;
  String? currentDisplayName;

  // String? currentEmail; // Keep if needed, currently not used in build directly

  bool _isLoadingProfile = true; // Added for loading state

  Future<void> _initializeControllers() async {
    if (currentUser == null) {
      // If there's no current user, no need to fetch data.
      // You might want to navigate to login or show a specific UI.
      setState(() {
        _isLoadingProfile = false;
      });
      debugPrint("MenuScreen: No current user found.");
      return;
    }
    try {
      final userData = await supabase.Supabase.instance.client
          .from('users')
          .select(
              'display_name, email, profile_image') // Select specific columns
          .eq('id', currentUser!.id) // currentUser is checked for null above
          .single();

      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          currentDisplayName = userData['display_name'] as String? ?? '';
          // currentEmail = userData['email'] as String? ?? '';
          currentProfileImage = userData['profile_image'] as String?;
          _isLoadingProfile = false;
          debugPrint('currentProfileImage: $currentProfileImage');
          debugPrint('currentDisplayName: $currentDisplayName');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
      debugPrint("Error initializing controllers: ${e.toString()}");
      // Optionally show a snackbar or error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText('Error loading profile data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers(); // No need to await here directly, setState handles UI update
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sectionHeaderColor = _getSectionHeaderColor(context, isDarkMode);

    if (_isLoadingProfile && currentUser != null) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Not logged in."),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          LoginScreen(authService: widget.authService),
                    ),
                  );
                },
                child: const Text("Go to Login"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildProfile(),
          const Divider(),
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

  Widget _buildProfile() {
    ImageProvider<Object>? profileImageProvider;

    if (currentProfileImage != null && currentProfileImage!.isNotEmpty) {
      profileImageProvider = CachedNetworkImageProvider(currentProfileImage!);
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
      title: Text(currentDisplayName ?? 'User Profile'),
      // Default text if null
      subtitle: currentUser?.email != null ? Text(currentUser!.email!) : null,
      // Display email if available
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            // TODO: Ensure AccountSetting() screen is correctly implemented and imported
            return UserProfile(
              displayName: currentDisplayName!,
              imageUrl: currentProfileImage!,
              email: currentUser!.email!,
            );
          },
        ));
      },
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
            // TODO: Ensure AccountSetting() screen is correctly implemented and imported
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
    // Ensure MyApp.of(context) and changeTheme are correctly implemented in main.dart
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
          // TODO: Get version programmatically if needed
          onTap: () {
            // Could show an About Dialog
          },
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
        content: Text('View Privacy Policy (Not Implemented)'),
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
        Navigator.of(context).pop(); // Pops the dialog
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(authService: widget.authService),
          ),
          (Route<dynamic> route) => false, // This predicate removes all routes
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
      debugPrint("Error during logout: ${e.toString()}");
    }
  }
}
