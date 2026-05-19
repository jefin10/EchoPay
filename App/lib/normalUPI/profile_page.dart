import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'profile_account_page.dart';
import 'profile_security_page.dart';
import 'profile_about_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String _userName = '';
  String _userPhone = '';
  String _userUPI = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    if (phoneNumber == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _userPhone = phoneNumber);
    try {
      final url = Uri.parse('$GET_PROFILE_URL?phoneNumber=$phoneNumber');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _userName = data['upiName'] ?? '';
          _userUPI = data['upiId'] ?? '';
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _copyUpiId() {
    if (_userUPI.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _userUPI));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('UPI ID copied'),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log out?', style: AppTypography.heading(size: 22)),
              const SizedBox(height: 10),
              Text(
                'You will need to verify your number again to come back.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/phone');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Log out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankAccountsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _sheet(
        title: 'Bank accounts',
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.account_balance_outlined,
                        color: AppColors.ink, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text('No bank accounts linked',
                      style: AppTypography.heading(size: 16)),
                  const SizedBox(height: 6),
                  const Text(
                    'Bank account linking is powered by your UPI handle. Payments go directly through your registered UPI.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text('Your UPI ID',
                            style: AppTypography.eyebrow(size: 10)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _userUPI.isEmpty ? '—' : _userUPI,
                            style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLimitsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _sheet(
        title: 'Transaction limits',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _limitRow('Per transaction', '₹1,00,000'),
              _sheetDivider(),
              _limitRow('Daily limit', '₹1,00,000'),
              _sheetDivider(),
              _limitRow('Per month', '₹10,00,000'),
              _sheetDivider(),
              _limitRow('Transactions/day', '20 transfers'),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NotificationsSheet(),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _sheet(
        title: 'Help & support',
        child: Column(
          children: [
            _faqItem('How do I send money by voice?',
                'Tap the mic on the home screen and say "Send ₹500 to [name or phone]". EchoPay will identify the recipient and confirm before transferring.'),
            const SizedBox(height: 10),
            _faqItem('What if a payment fails?',
                'Failed payments are not deducted. If your balance was deducted and the recipient did not receive the amount, it will be refunded within 3 business days.'),
            const SizedBox(height: 10),
            _faqItem('How do I check my balance?',
                'Say "What is my balance?" to the voice assistant, tap the wallet card on home, or go to the Balance tab.'),
            const SizedBox(height: 10),
            _faqItem('Is my data secure?',
                'All payments require biometric authentication. Your UPI PIN is never stored on this device.'),
          ],
        ),
      ),
    );
  }

  Widget _sheet({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(title, style: AppTypography.heading(size: 20)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _limitRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _sheetDivider() => Container(
        height: 1,
        color: AppColors.divider,
        margin: const EdgeInsets.symmetric(horizontal: 18),
      );

  Widget _faqItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(answer,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: 24),
              _profileCard(),
              const SizedBox(height: 24),
              Text('preferences', style: AppTypography.eyebrow()),
              const SizedBox(height: 12),
              _menuList(),
              const SizedBox(height: 20),
              _logoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        Text('profile', style: AppTypography.heading(size: 22)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSecurityPage()),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.settings_outlined,
                color: AppColors.ink, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _profileCard() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(
                color: AppColors.pop, strokeWidth: 2),
          ),
        ),
      );
    }

    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.pop,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isEmpty ? 'Loading...' : _userName,
                      style: AppTypography.heading(
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userPhone,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _copyUpiId,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Text(
                    'upi id',
                    style: AppTypography.eyebrow(
                        color: Colors.white.withOpacity(0.6), size: 10),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _userUPI.isEmpty ? '—' : _userUPI,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.copy_rounded,
                      color: AppColors.pop, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _menuItem(
            Icons.person_outline_rounded,
            'Account details',
            'Name, UPI ID & balance',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileAccountPage()),
            ),
          ),
          _divider(),
          _menuItem(
            Icons.account_balance_outlined,
            'Bank accounts',
            'Manage linked accounts',
            _showBankAccountsSheet,
          ),
          _divider(),
          _menuItem(
            Icons.shield_outlined,
            'Security',
            'PIN & biometric settings',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileSecurityPage()),
            ),
          ),
          _divider(),
          _menuItem(
            Icons.tune_rounded,
            'Transaction limits',
            'View & update limits',
            _showLimitsSheet,
          ),
          _divider(),
          _menuItem(
            Icons.notifications_none_rounded,
            'Notifications',
            'Manage alerts',
            _showNotificationsSheet,
          ),
          _divider(),
          _menuItem(
            Icons.help_outline_rounded,
            'Help & support',
            'FAQs & contact',
            _showHelpSheet,
          ),
          _divider(),
          _menuItem(
            Icons.info_outline_rounded,
            'About',
            'App version & legal',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileAboutPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.ink, size: 20),
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
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        color: AppColors.divider,
      );

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded,
            color: AppColors.coral, size: 18),
        label: const Text(
          'Log out',
          style: TextStyle(
              color: AppColors.coral,
              fontSize: 14,
              fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: AppColors.coral.withOpacity(0.5), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// Separate stateful widget for notifications toggles in the bottom sheet
class _NotificationsSheet extends StatefulWidget {
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _payments = true;
  bool _requests = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _payments = prefs.getBool('notif_payments') ?? true;
      _requests = prefs.getBool('notif_requests') ?? true;
      _promotions = prefs.getBool('notif_promotions') ?? false;
    });
  }

  Future<void> _save(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Notifications', style: AppTypography.heading(size: 20)),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _toggleRow('Payment alerts', 'Sent & received confirmations',
                    _payments, (v) {
                  setState(() => _payments = v);
                  _save('notif_payments', v);
                }),
                Container(
                    height: 1,
                    color: AppColors.divider,
                    margin: const EdgeInsets.symmetric(horizontal: 18)),
                _toggleRow('Money requests', 'When someone requests money',
                    _requests, (v) {
                  setState(() => _requests = v);
                  _save('notif_requests', v);
                }),
                Container(
                    height: 1,
                    color: AppColors.divider,
                    margin: const EdgeInsets.symmetric(horizontal: 18)),
                _toggleRow('Offers & updates', 'App news and promotions',
                    _promotions, (v) {
                  setState(() => _promotions = v);
                  _save('notif_promotions', v);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.pop,
            thumbColor: WidgetStateProperty.all(AppColors.ink),
          ),
        ],
      ),
    );
  }
}
