import 'package:flutter/material.dart';

class AppColors {
  // EchoPay brand color scheme (blue theme based on logo)
  
  // Primary Colors - EchoPay blue theme (inspired by logo)
  static const Color primary = Color(0xFF0066FF); // main brand blue
  static const Color primaryDark = Color(0xFF0052CC);
  static const Color primaryLight = Color(0xFF338EFF);
  
  // Legacy aliases for compatibility (no longer used but kept for reference)
  static const Color primaryBlue = primary;
  static const Color primarySky = primaryLight;
  static const Color primaryNavy = primaryDark;
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF1C1C1E);
  static const Color backgroundMedium = Color(0xFF2C2C2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundLight = Color(0xFFF8F8FA);
  
  // Accent Colors
  static const Color accentGreen = Color(0xFF00C853);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentYellow = Color(0xFFFFEB3B);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF8E8E93);
  static const Color textGrayLight = Color(0xFFAEAEB2);
  static const Color textGrayDark = Color(0xFF48484A);
  static const Color textMuted = Color(0xFFB4B4B8);
  
  // Status Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Divider & Border
  static const Color divider = Color(0xFFE5E5EA);
  static const Color border = Color(0xFFD1D1D6);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5F259F), Color(0xFF4A1D7A)],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F8FA)],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), Color(0xFF00A846)],
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
  );
}
