import 'package:flutter/material.dart';

class AppColors {
  // POP UPI palette — deep violet ink + warm cream + crisp accents
  // Inspired by Cred / Jupiter visual language (no rainbow gradients).

  // Primary — deep violet ink
  static const Color primary = Color(0xFF3B1F8C);
  static const Color primaryDark = Color(0xFF26145C);
  static const Color primaryLight = Color(0xFFEDE7FB);

  // Aliases retained for legacy imports — point to the new palette
  static const Color primaryBlue = primary;
  static const Color primarySky = primaryLight;
  static const Color primaryNavy = primaryDark;

  // POP accents — used sparingly as flat single-colour highlights
  static const Color pop = Color(0xFFFFB800);        // signature yellow
  static const Color popSoft = Color(0xFFFFF1C2);
  static const Color coral = Color(0xFFFF5A5F);
  static const Color mint = Color(0xFF10B981);
  static const Color sky = Color(0xFF2563EB);

  // Backgrounds — warm cream rather than cold grey
  static const Color surfaceLight = Color(0xFFF5F1E6);   // page background
  static const Color surface = Color(0xFFFFFFFF);        // card background
  static const Color surfaceDim = Color(0xFFEDE8DA);     // input fill
  static const Color cardBackground = surface;
  static const Color cardBackgroundLight = Color(0xFFFAF7EE);
  static const Color backgroundDark = Color(0xFF15102E);
  static const Color backgroundMedium = Color(0xFF221A47);

  // Ink & text
  static const Color ink = Color(0xFF14122B);
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF6B6883);
  static const Color textMuted = Color(0xFF9B98AE);
  static const Color textGray = Color(0xFF8E8BA3);
  static const Color textGrayLight = Color(0xFFB0AEC0);
  static const Color textGrayDark = Color(0xFF3F3D55);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status — flat, single tone
  static const Color success = mint;
  static const Color error = coral;
  static const Color warning = Color(0xFFEAA000);
  static const Color info = sky;

  // Accent aliases (kept for backwards compatibility)
  static const Color accentGreen = mint;
  static const Color accentBlue = sky;
  static const Color accentOrange = warning;
  static const Color accentRed = coral;
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentYellow = pop;

  // Borders & dividers — thin, deliberate
  static const Color border = Color(0xFFE0DBCB);
  static const Color borderStrong = Color(0xFFC9C2AC);
  static const Color divider = Color(0xFFE6E1D2);

  // Gradients are deliberately removed from the palette.
  // Pages should use flat colours; these constants exist only to keep
  // legacy imports compiling. They are single-tone (effectively flat).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primary],
  );
  static const LinearGradient headerGradient = primaryGradient;
  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, surface],
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [mint, mint],
  );
  static const LinearGradient blueGradient = LinearGradient(
    colors: [sky, sky],
  );
}
