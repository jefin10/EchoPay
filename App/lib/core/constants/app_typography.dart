import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralised typography for the POP UPI theme.
///
/// We use Sora — a geometric sans serif with strong personality at heavy
/// weights — for display text, and Plus Jakarta Sans for body copy.
class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final body = GoogleFonts.plusJakartaSansTextTheme(base).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    final displayFont = GoogleFonts.sora(
      color: AppColors.ink,
      letterSpacing: -0.5,
    );

    return body.copyWith(
      displayLarge: displayFont.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.2,
      ),
      displayMedium: displayFont.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.0,
      ),
      displaySmall: displayFont.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineLarge: displayFont.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineMedium: displayFont.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineSmall: displayFont.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    );
  }

  /// Display font for amounts, balances and other numeric POP moments.
  static TextStyle amount({
    double size = 36,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w800,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -1.0,
      height: 1.0,
    );
  }

  /// Display font for headings.
  static TextStyle heading({
    double size = 22,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = -0.3,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Tight uppercase eyebrow / chip label.
  static TextStyle eyebrow({
    Color color = AppColors.textSecondary,
    double size = 11,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 1.6,
    );
  }
}
