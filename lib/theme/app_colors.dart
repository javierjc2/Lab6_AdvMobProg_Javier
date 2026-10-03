import 'package:flutter/material.dart';

/// Central color palette for the app's light theme.
///
/// This file only defines colors/styling constants — none of the
/// cart, product, or provider logic depends on it, so it's safe to
/// tweak these values any time you want to adjust the look.
class AppColors {
  AppColors._();

  // Deep navy/indigo used for the AppBar, selected nav item, etc.
  static const Color primaryNavy = Color(0xFF322F6D);
  static const Color primaryNavyDark = Color(0xFF262452);

  // Warm amber/gold accent used for prices, +/- buttons, and the
  // primary "Confirm Order" call-to-action button.
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color accentAmberDark = Color(0xFFE6A100);

  // Neutral surface colors.
  static const Color background = Color(0xFFF6F6FA);
  static const Color cardBackground = Colors.white;

  // Text colors.
  static const Color textDark = Color(0xFF1E1E2C);
  static const Color textGrey = Color(0xFF8C8C99);
  static const Color textOnAmber = Color(0xFF2A2200);
}
