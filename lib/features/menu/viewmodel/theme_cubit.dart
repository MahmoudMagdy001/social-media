import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(themeMode: ThemeMode.light)) {
    _loadThemePreference();
  }

  static const String _themePreferenceKey = 'theme_preference';

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePreferenceKey) ?? 'light';
    final themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    emit(ThemeState(themeMode: themeMode));
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themePreferenceKey,
      themeMode.toString().split('.').last,
    );
    emit(ThemeState(themeMode: themeMode));
  }
}
