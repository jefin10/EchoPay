import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'phone_number_page.dart';
import 'verify_otp_page.dart';
import 'name_entry_page.dart';
import 'normalUPI/landing.dart';
import 'constants/app_colors.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
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
    return MaterialApp(
      title: 'EchoPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
          background: AppColors.surfaceLight,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.surfaceLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: _isLoggedIn ? '/biometric' : '/phone',
      routes: {
        '/phone': (context) => const PhoneNumberPage(),
        '/verify-otp': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
          return VerifyOtpPage(
            phoneNumber: args?['phoneNumber'] ?? '',
          );
        },
        '/name-entry': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
          return NameEntryPage(
            phoneNumber: args?['phoneNumber'] ?? '',
          );
        },
        '/biometric': (context) => const BiometricAuthScreen(),
        '/main': (context) => MyHomePage(title: 'UPI Voice App'),
      },
    );
  }
}

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> with SingleTickerProviderStateMixin {
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
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
        _authStatus = 'Authenticating...';
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

      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
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
        setState(() {
          _authStatus = 'Success!';
        });
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
    setState(() {
      _authStatus = 'Biometric not available';
    });
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // App Logo with pulse animation
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // App Title
                  const Text(
                    'EchoPay',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure Payment App',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isAuthenticating)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        if (_isAuthenticating) const SizedBox(width: 12),
                        Text(
                          _authStatus,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Retry button
                  if (!_isAuthenticating)
                    TextButton(
                      onPressed: _authenticateWithBiometrics,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
          ),
        ),
      )));
    
  }
}
