import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/widgets/motion.dart';
import '../../home/providers/account_providers.dart';

class BalancePage extends ConsumerStatefulWidget {
  const BalancePage({super.key});

  @override
  ConsumerState<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends ConsumerState<BalancePage> {
  bool _isBalanceVisible = true;

  Future<void> _refresh() => ref.read(balanceProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceProvider);
    final userName = ref.watch(sessionStoreProvider).userName ?? 'User';
    final balance = balanceAsync.valueOrNull;
    final error = balanceAsync.hasError
        ? 'Failed to fetch balance. Pull to retry.'
        : null;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Entrance(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(),
                const SizedBox(height: 28),
                _balanceCard(balanceAsync.isLoading, balance, userName),
                const SizedBox(height: 22),
                if (error != null) _errorCard(error),
                if (balance != null && error == null) _bankCard(balance),
              ],
              ),
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
        Text('balance', style: AppTypography.heading(size: 22)),
        const Spacer(),
        Pressable(
          scale: 0.9,
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
        Pressable(
          scale: 0.9,
          onTap: _refresh,
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

  Widget _balanceCard(bool isLoading, double? balance, String userName) {
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
            'hi, ${userName.toLowerCase()}',
            style: AppTypography.eyebrow(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'available balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          if (isLoading)
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
                    color: Colors.white.withValues(alpha: 0.8),
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isBalanceVisible
                      ? (balance?.toStringAsFixed(2) ?? '0.00')
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

  Widget _errorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.coral, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _refresh,
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

  Widget _bankCard(double balance) {
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
                  color: AppColors.mint.withValues(alpha: 0.12),
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
                    ? '₹${balance.toStringAsFixed(2)}'
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
