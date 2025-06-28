import 'package:flutter/material.dart';

class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({required this.themeMode});

  @override
  String toString() {
    return themeMode.toString();
  }
}
