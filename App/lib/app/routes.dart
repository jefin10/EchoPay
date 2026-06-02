import 'package:flutter/material.dart';

import '../features/auth/pages/biometric_page.dart';
import '../features/auth/pages/name_entry_page.dart';
import '../features/auth/pages/phone_number_page.dart';
import '../features/auth/pages/verify_otp_page.dart';
import '../features/home/pages/dashboard_page.dart';

/// Named routes for the app. Argument extraction lives here so individual
/// pages stay free of `ModalRoute` lookups.
class AppRoutes {
  static const phone = '/phone';
  static const verifyOtp = '/verify-otp';
  static const nameEntry = '/name-entry';
  static const biometric = '/biometric';
  static const main = '/main';

  static Map<String, WidgetBuilder> get all => {
        phone: (_) => const PhoneNumberPage(),
        verifyOtp: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, String>?;
          return VerifyOtpPage(phoneNumber: args?['phoneNumber'] ?? '');
        },
        nameEntry: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, String>?;
          return NameEntryPage(phoneNumber: args?['phoneNumber'] ?? '');
        },
        biometric: (_) => const BiometricAuthScreen(),
        main: (_) => const DashboardPage(),
      };
}
