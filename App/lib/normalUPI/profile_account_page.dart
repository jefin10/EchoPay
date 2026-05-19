import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class ProfileAccountPage extends StatefulWidget {
  const ProfileAccountPage({super.key});

  @override
  State<ProfileAccountPage> createState() => _ProfileAccountPageState();
}

class _ProfileAccountPageState extends State<ProfileAccountPage> {
  bool _loading = true;
  String? _name;
  String? _phone;
  String? _upiId;
  String? _balance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    setState(() => _phone = phone);

    if (phone == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        http.get(Uri.parse('$GET_PROFILE_URL?phoneNumber=$phone')),
        http.get(Uri.parse('$GET_BALANCE_URL?phoneNumber=$phone')),
      ]);

      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body);
        setState(() {
          _name = data['upiName'];
          _upiId = data['upiId'];
        });
      }
      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body);
        setState(() => _balance = data['balance']);
      }
    } catch (_) {}

    setState(() => _loading = false);
  }

  void _copyUpiId() {
    if (_upiId == null) return;
    Clipboard.setData(ClipboardData(text: _upiId!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('UPI ID copied'),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: 22),
              Text('your account', style: AppTypography.eyebrow()),
              const SizedBox(height: 6),
              Text(
                'Account\nDetails.',
                style: AppTypography.heading(size: 30, weight: FontWeight.w800)
                    .copyWith(height: 1.05),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: CircularProgressIndicator(
                        color: AppColors.ink, strokeWidth: 2.5),
                  ),
                )
              else
                _content(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
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
        Text('account details', style: AppTypography.heading(size: 18)),
      ],
    );
  }

  Widget _content() {
    final initial =
        (_name?.isNotEmpty == true) ? _name![0].toUpperCase() : 'U';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
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
                          _name ?? 'Unknown',
                          style: AppTypography.heading(
                              size: 20, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _phone ?? '',
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
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _copyUpiId,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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
                          _upiId ?? 'N/A',
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
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
                child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.ink,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('wallet balance', style: AppTypography.eyebrow()),
                    const SizedBox(height: 4),
                    Text(
                      _balance != null
                          ? '₹${double.tryParse(_balance!)?.toStringAsFixed(2) ?? _balance}'
                          : '—',
                      style: AppTypography.heading(size: 20),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('ACTIVE',
                    style: AppTypography.eyebrow(
                        color: AppColors.mint, size: 9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _infoRow(Icons.person_outline_rounded, 'Display name',
                  _name ?? '—'),
              _divider(),
              _infoRow(
                  Icons.smartphone_rounded, 'Phone number', _phone ?? '—'),
              _divider(),
              _infoRow(Icons.alternate_email_rounded, 'UPI handle',
                  _upiId ?? '—'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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
                  label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        color: AppColors.divider,
      );
}
