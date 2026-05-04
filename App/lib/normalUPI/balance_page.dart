import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  double? _currentBalance;
  bool _isLoading = true;
  String? _error;
  bool _isBalanceVisible = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    if (phoneNumber == null) {
      setState(() {
        _isLoading = false;
        _error = 'Phone number not found. Please log in again.';
      });
      return;
    }
    try {
      final url = Uri.parse('$GET_BALANCE_URL?phoneNumber=$phoneNumber');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentBalance = double.tryParse(data['balance'].toString());
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to fetch balance';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: _fetchBalance,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(),
                const SizedBox(height: 28),
                _balanceCard(),
                const SizedBox(height: 22),
                if (_error != null) _errorCard(),
                if (_currentBalance != null && _error == null) _bankCard(),
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
        Text('balance', style: AppTypography.heading(size: 22)),
        const Spacer(),
        GestureDetector(
          onTap: () =>
              setState(() => _isBalanceVisible = !_isBalanceVisible),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              _isBalanceVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.ink,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _fetchBalance,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.ink, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userName != null ? 'hi, ${_userName!.toLowerCase()}' : 'hello',
            style: AppTypography.eyebrow(
              color: Colors.white.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'available balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹',
                  style: AppTypography.amount(
                    size: 32,
                    color: Colors.white.withOpacity(0.8),
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isBalanceVisible
                      ? (_currentBalance?.toStringAsFixed(2) ?? '0.00')
                      : '••••••',
                  style: AppTypography.amount(
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.pop,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded,
                    color: AppColors.ink, size: 14),
                const SizedBox(width: 4),
                Text(
                  'instant',
                  style: AppTypography.eyebrow(
                    color: AppColors.ink,
                    size: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coral.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coral.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.coral, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _fetchBalance,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_outlined,
                    color: AppColors.ink, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank account', style: AppTypography.heading(size: 16)),
                    const SizedBox(height: 2),
                    Text(
                      'Linked & active',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
                  style: AppTypography.eyebrow(
                    color: AppColors.mint,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current balance',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _isBalanceVisible
                    ? '₹${_currentBalance!.toStringAsFixed(2)}'
                    : '₹••••••',
                style: AppTypography.amount(
                  size: 18,
                  color: AppColors.ink,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
