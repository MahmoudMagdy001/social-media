import 'package:facebook_clone/consts/theme.dart';
import 'package:facebook_clone/screens/Auth/login_screen.dart';
import 'package:facebook_clone/screens/layout/layout_screen.dart';
import 'package:facebook_clone/services/auth_services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    const String databaseUrl = 'https://ikybwhywdnsrzvcbgrwj.supabase.co';
    const String anonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlreWJ3aHl3ZG5zcnp2Y2JncndqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyNDg5NDgsImV4cCI6MjA2NDgyNDk0OH0.oav7OQZVjc9Nvc4nJsFckyl0iz0EHIYn92bBbEF5DTk';

    await Supabase.initialize(url: databaseUrl, anonKey: anonKey);
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themePreferenceKey = 'theme_preference';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    String savedTheme = prefs.getString(_themePreferenceKey) ?? 'light';
    setState(() {
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _saveThemePreference(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themePreferenceKey,
      themeMode.toString().split('.').last,
    );
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
    _saveThemePreference(themeMode);
  }

  Future<Widget> _checkLoginStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return LayoutScreen(
        authService: _authService,
      );
    } else {
      return LoginScreen(
        authService: _authService,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        //TODO add bloc pattern

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          home: snapshot.data!,
        );
      },
    );
  }
}
