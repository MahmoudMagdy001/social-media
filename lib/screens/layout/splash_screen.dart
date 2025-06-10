import 'package:facebook_clone/services/auth_services/auth_service.dart'; // Your AuthService
import 'package:flutter/material.dart';

import '../../widgets/custom_text.dart';
import '../Auth/login_screen.dart';
import 'layout_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  static const _splashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndNavigate();
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;

    final user = await _authService.currentUser;
    final nextScreen = user != null
        ? LayoutScreen(userData: user, authService: _authService)
        : LoginScreen(authService: _authService);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.facebook, size: 100, color: Colors.blue),
              CustomText(
                'dodybook',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
