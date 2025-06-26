import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // --- Light Theme Colors ---
  static final Color _lightPrimary = const Color(0xFF1A73E8); // Google Blue
  static final Color _lightOnPrimary = Colors.white;
  static final Color _lightPrimaryContainer =
      const Color(0xFFD2E3FC); // Lighter variant
  static final Color _lightOnPrimaryContainer =
      const Color(0xFF001D36); // Dark blue
  static final Color _lightSecondary = const Color(0xFF03DAC6); // Teal
  static final Color _lightOnSecondary = Colors.black;
  static final Color _lightSurface = Colors.white;
  static final Color _lightOnSurface = const Color(0xFF1C1B1F); // Dark gray
  static final Color _lightError = const Color(0xFFB3261E); // Material 3 error
  static final Color _lightOnError = Colors.white;
  static final Color _lightOutline =
      const Color(0xFF79747E); // Material 3 outline
  static final Color _lightScafooldBackground =
      const Color(0xFFF5F5F5); // Light gray

  // --- Dark Theme Colors ---
  static final Color _darkPrimary = const Color(0xFF1A73E8); // Google Blue
  static final Color _darkOnPrimary = Colors.white;
  static final Color _darkPrimaryContainer =
      const Color(0xFF1A73E8); // Google Blue
  static final Color _darkOnPrimaryContainer = Colors.white;
  static final Color _darkSecondary = const Color(0xFF03DAC6); // Teal
  static final Color _darkOnSecondary = Colors.black;
  static final Color _darkSurface = const Color(0xFF1C1B1F); // Dark gray
  static final Color _darkOnSurface = Colors.white;
  static final Color _darkError = const Color(0xFFF2B8B5); // Material 3 error
  static final Color _darkOnError = Colors.black;
  static final Color _darkOutline =
      const Color(0xFF938F99); // Material 3 outline
  static final Color _darkScaffoldBackground =
      const Color(0xFF121212); // Material dark

  // --- Common Text Styles ---
  static const _baseTextStyle = TextStyle(
    fontFamily: 'Roboto',
    letterSpacing: 0.15,
  );

  static final TextTheme _lightTextTheme = TextTheme(
    displayLarge: _baseTextStyle.copyWith(
      fontSize: 32.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _lightOnSurface,
    ),
    headlineMedium: _baseTextStyle.copyWith(
      fontSize: 24.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _lightOnSurface,
    ),
    titleLarge: _baseTextStyle.copyWith(
      fontSize: 22.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: _lightOnSurface,
    ),
    bodyLarge: _baseTextStyle.copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: _lightOnSurface.withAlpha(222), // 0.87 * 255 ≈ 222
    ),
    bodyMedium: _baseTextStyle.copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: _lightOnSurface.withAlpha(153), // 0.6 * 255 ≈ 153
    ),
    labelLarge: _baseTextStyle.copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Colors.white,
    ),
  ).apply(
    bodyColor: _lightOnSurface,
    displayColor: _lightOnSurface,
  );

  static final TextTheme _darkTextTheme = TextTheme(
    displayLarge: _baseTextStyle.copyWith(
      fontSize: 32.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _darkOnSurface,
    ),
    headlineMedium: _baseTextStyle.copyWith(
      fontSize: 24.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _darkOnSurface,
    ),
    titleLarge: _baseTextStyle.copyWith(
      fontSize: 22.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: _darkOnSurface,
    ),
    bodyLarge: _baseTextStyle.copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: _darkOnSurface.withAlpha(222), // 0.87 * 255 ≈ 222
    ),
    bodyMedium: _baseTextStyle.copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: _darkOnSurface.withAlpha(153), // 0.6 * 255 ≈ 153
    ),
    labelLarge: _baseTextStyle.copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Colors.white,
    ),
  ).apply(
    bodyColor: _darkOnSurface,
    displayColor: _darkOnSurface,
  );

  // --- Light Theme Definition ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      primaryContainer: _lightPrimaryContainer,
      onPrimaryContainer: _lightOnPrimaryContainer,
      secondary: _lightSecondary,
      onSecondary: _lightOnSecondary,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      error: _lightError,
      onError: _lightOnError,
      outline: _lightOutline,
    ),
    scaffoldBackgroundColor: _lightScafooldBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightSurface,
      foregroundColor: _lightOnSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _lightTextTheme.titleLarge?.copyWith(
        color: _lightOnSurface,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(
        color: _lightOnSurface,
        size: 24,
      ),
    ),
    textTheme: _lightTextTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide:
            BorderSide(color: _lightOutline.withAlpha(128)), // 0.5 * 255 ≈ 128
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide:
            BorderSide(color: _lightOutline.withAlpha(128)), // 0.5 * 255 ≈ 128
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _lightPrimary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _lightError),
      ),
      labelStyle: _lightTextTheme.bodyMedium?.copyWith(
        color: _lightOnSurface.withAlpha(153), // 0.6 * 255 ≈ 153
      ),
      hintStyle: _lightTextTheme.bodyMedium?.copyWith(
        color: _lightOnSurface.withAlpha(128), // 0.5 * 255 ≈ 128
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        textStyle: _lightTextTheme.labelLarge?.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2.0,
        minimumSize: const Size(88, 48),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _lightPrimary,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: _lightOutline.withAlpha(51), // 0.2 * 255 ≈ 51
      thickness: 1.0,
      space: 24.0,
    ),
  );

  // --- Dark Theme Definition ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      primaryContainer: _darkPrimaryContainer,
      onPrimaryContainer: _darkOnPrimaryContainer,
      secondary: _darkSecondary,
      onSecondary: _darkOnSecondary,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      error: _darkError,
      onError: _darkOnError,
      outline: _darkOutline,
    ),
    scaffoldBackgroundColor: _darkScaffoldBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: _darkOnSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _darkTextTheme.titleLarge?.copyWith(
        color: _darkOnSurface,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(
        color: _darkOnSurface,
        size: 24,
      ),
    ),
    textTheme: _darkTextTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface.withAlpha(12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide:
            BorderSide(color: _darkOutline.withAlpha(128)), // 0.5 * 255 ≈ 128
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide:
            BorderSide(color: _darkOutline.withAlpha(128)), // 0.5 * 255 ≈ 128
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _darkPrimary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _darkError),
      ),
      labelStyle: _darkTextTheme.bodyMedium?.copyWith(
        color: _darkOnSurface.withAlpha(153), // 0.6 * 255 ≈ 153
      ),
      hintStyle: _darkTextTheme.bodyMedium?.copyWith(
        color: _darkOnSurface.withAlpha(128), // 0.5 * 255 ≈ 128
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        textStyle: _darkTextTheme.labelLarge?.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2.0,
        minimumSize: const Size(88, 48),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _darkPrimary,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: _darkOutline.withAlpha(51), // 0.2 * 255 ≈ 51
      thickness: 1.0,
      space: 24.0,
    ),
  );
}
