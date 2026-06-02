import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/motion.dart';
import '../../home/pages/dashboard_page.dart';

class BiometricAuthScreen extends ConsumerStatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  ConsumerState<BiometricAuthScreen> createState() =>
      _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends ConsumerState<BiometricAuthScreen>
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
      CurvedAnimation(parent: _pulseController, curve: AppMotion.inOut),
    );
    Future.delayed(
        const Duration(milliseconds: 500), _authenticateWithBiometrics);
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
        await ref.read(sessionStoreProvider).setLoggedIn(true);
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
        MaterialPageRoute(builder: (context) => const DashboardPage()),
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
              AppButton(
                label: 'Authenticate',
                icon: Icons.fingerprint_rounded,
                loading: _isAuthenticating,
                onPressed:
                    _isAuthenticating ? null : _authenticateWithBiometrics,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
