import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'phone_number_page.dart';
import 'verify_otp_page.dart';
import 'name_entry_page.dart';
import 'normalUPI/landing.dart';
import 'constants/app_colors.dart';
import 'constants/app_typography.dart';
import 'widgets/app_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    return MaterialApp(
      title: 'EchoPay',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.pop,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.surfaceLight,
        textTheme: AppTypography.textTheme(base.textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.sora(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          iconTheme: const IconThemeData(color: AppColors.ink),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.ink,
          contentTextStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        dividerColor: AppColors.divider,
      ),
      initialRoute: _isLoggedIn ? '/biometric' : '/phone',
      routes: {
        '/phone': (context) => const PhoneNumberPage(),
        '/verify-otp': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
          return VerifyOtpPage(phoneNumber: args?['phoneNumber'] ?? '');
        },
        '/name-entry': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
          return NameEntryPage(phoneNumber: args?['phoneNumber'] ?? '');
        },
        '/biometric': (context) => const BiometricAuthScreen(),
        '/main': (context) => const MyHomePage(title: 'EchoPay'),
      },
    );
  }
}

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authStatus = 'Tap to authenticate';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 500), _authenticateWithBiometrics);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authStatus = 'Authenticating';
      });

      final bool isDeviceSupported = await auth.isDeviceSupported();
      if (!isDeviceSupported) {
        _navigateDirectly();
        return;
      }
      final bool canUseBiometrics = await auth.canCheckBiometrics;
      if (!canUseBiometrics) {
        _navigateDirectly();
        return;
      }
      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _navigateDirectly();
        return;
      }

      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access EchoPay',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      if (authenticated) {
        setState(() => _authStatus = 'Welcome back');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await Future.delayed(const Duration(milliseconds: 300));
        _navigateToMain();
      } else {
        setState(() {
          _authStatus = 'Authentication cancelled';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Tap to try again';
      });
    }
  }

  void _navigateDirectly() {
    setState(() => _authStatus = 'Biometric not available');
    Future.delayed(const Duration(milliseconds: 800), _navigateToMain);
  }

  void _navigateToMain() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'EchoPay'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EchoPay', style: AppTypography.heading(size: 22)),
              const Spacer(),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: AppColors.borderStrong,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: AppLogo(type: LogoType.iconOnly),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Pay smarter,\nspeak faster.',
                style: AppTypography.heading(size: 36, weight: FontWeight.w800)
                    .copyWith(height: 1.05),
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock to continue to your wallet.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    if (_isAuthenticating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.pop,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      _authStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAuthenticating ? null : _authenticateWithBiometrics,
                  child: const Text('Authenticate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
