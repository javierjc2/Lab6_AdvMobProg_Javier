import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Light theme styled to match the app's design reference:
// navy AppBar / nav bar, amber accent buttons, soft grey background.
final ThemeData _appLightTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryNavy,
  colorScheme: ThemeData.light().colorScheme.copyWith(
    primary: AppColors.primaryNavy,
    secondary: AppColors.accentAmber,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primaryNavy,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryNavy,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primaryNavy,
    unselectedItemColor: AppColors.textGrey,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentAmber,
      foregroundColor: AppColors.textOnAmber,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => AppColors.primaryNavy,
    ),
  ),
  // Enhancement 2: shared rounded/outlined field style used by the new
  // sign-in form.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardBackground,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  ),
);

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = _appLightTheme; // Default theme state

  // 1. Fixes the 'currentTheme' error in main.dart
  ThemeData get currentTheme => _currentTheme;

  // 2. FIXES THE NEW ERROR: Alias 'theme' for whatever file is looking for it
  ThemeData get theme => _currentTheme;

  // 3. Fixes the 'isDark' error in your settings screen
  bool get isDark => _currentTheme.brightness == Brightness.dark;

  // Additional alias just in case any file looks for 'isDarkMode'
  bool get isDarkMode => isDark;

  void toggleTheme() {
    if (isDark) {
      _currentTheme = _appLightTheme;
    } else {
      _currentTheme = _appDarkTheme;
    }
    notifyListeners();
  }
  final ThemeData _appDarkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF12121A),
    primaryColor: AppColors.primaryNavy,
    colorScheme: ThemeData.dark().colorScheme.copyWith(
      primary: const Color(0xFF9D99F2),
      secondary: AppColors.accentAmber,
      surface: const Color(0xFF1D1D29),
      onSurface: const Color(0xFFF2F1F7),
      onSurfaceVariant: const Color(0xFFB9B7C5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1D1D29),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1D1D29),
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1D1D29),
      selectedItemColor: Color(0xFF9D99F2),
      unselectedItemColor: Color(0xFFB9B7C5),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentAmber,
        foregroundColor: AppColors.textOnAmber,
        elevation: 0,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1D1D29),
    ),
  );
}
