import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../widgets/motion.dart';

class ProfileSecurityPage extends StatefulWidget {
  const ProfileSecurityPage({super.key});

  @override
  State<ProfileSecurityPage> createState() => _ProfileSecurityPageState();
}

class _ProfileSecurityPageState extends State<ProfileSecurityPage> {
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometricEnabled') ?? true;
    });
  }

  Future<void> _toggleBiometric(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricEnabled', val);
    setState(() => _biometricEnabled = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Entrance(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: 22),
              Text('security', style: AppTypography.eyebrow()),
              const SizedBox(height: 6),
              Text(
                'Security\nSettings.',
                style: AppTypography.heading(size: 30, weight: FontWeight.w800)
                    .copyWith(height: 1.05),
              ),
              const SizedBox(height: 24),
              Text('authentication', style: AppTypography.eyebrow(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              _biometricCard(),
              const SizedBox(height: 20),
              Text('upi protection', style: AppTypography.eyebrow(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              _upiPinCard(),
              const SizedBox(height: 20),
              _noteCard(),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        Pressable(
          scale: 0.9,
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.ink, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Text('security', style: AppTypography.heading(size: 18)),
      ],
    );
  }

  Widget _biometricCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fingerprint_rounded,
                color: AppColors.ink, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biometric lock', style: AppTypography.heading(size: 15)),
                const SizedBox(height: 2),
                Text(
                  _biometricEnabled
                      ? 'Required before every payment'
                      : 'Payments skip biometric check',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _biometricEnabled,
            onChanged: _toggleBiometric,
            activeThumbColor: AppColors.ink,
            activeTrackColor: AppColors.pop,
          ),
        ],
      ),
    );
  }

  Widget _upiPinCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _staticRow(Icons.lock_outline_rounded, 'UPI PIN',
              'Managed by your bank app'),
          Container(
            height: 1,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: 18),
          ),
          _staticRow(Icons.verified_user_outlined, 'Transaction auth',
              'Biometric + UPI PIN on every transfer'),
          Container(
            height: 1,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: 18),
          ),
          _staticRow(Icons.shield_outlined, 'End-to-end encryption',
              'All payments are encrypted in transit'),
        ],
      ),
    );
  }

  Widget _staticRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.ink, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.popSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pop.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: AppColors.pop, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Always secure', style: AppTypography.heading(size: 14)),
                const SizedBox(height: 4),
                const Text(
                  'EchoPay requires biometric or device PIN before every payment. Your UPI PIN is never stored on this device.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
