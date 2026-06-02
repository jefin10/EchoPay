import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/motion.dart';
import '../../../models/transaction_item.dart';
import '../../home/providers/account_providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = const ['All', 'Sent', 'Received', 'Failed'];

  Future<void> _refresh() => ref.read(transactionsProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 14),
            _filterStrip(),
            const SizedBox(height: 14),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
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
          Text('history', style: AppTypography.heading(size: 22)),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.search_rounded,
                color: AppColors.ink, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _filterStrip() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _filters[i];
          final isSelected = filter == _selectedFilter;
          return Pressable(
            scale: 0.94,
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isSelected ? AppColors.ink : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    final txAsync = ref.watch(transactionsProvider);
    return txAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2.5),
      ),
      error: (_, __) => _emptyState(
          Icons.error_outline_rounded, 'Failed to fetch transactions.'),
      data: (transactions) {
        final filtered = _selectedFilter == 'All'
            ? transactions
            : transactions.where((tx) {
                if (_selectedFilter == 'Sent') return tx.isSent;
                if (_selectedFilter == 'Received') return !tx.isSent;
                if (_selectedFilter == 'Failed') return tx.status == 'failed';
                return true;
              }).toList();
        if (filtered.isEmpty) {
          return _emptyState(Icons.receipt_long_outlined,
              'Nothing here yet — your transactions will land here.');
        }
        return RefreshIndicator(
          color: AppColors.ink,
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _txTile(filtered[i]),
          ),
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.ink, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _txTile(TransactionItem tx) {
    final isSent = tx.isSent;
    final isCompleted = tx.status == 'completed';
    final statusColor = isCompleted ? AppColors.mint : AppColors.coral;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSent
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isSent ? AppColors.ink : AppColors.mint,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSent
                      ? 'To ${tx.counterpartyName}'
                      : 'From ${tx.counterpartyName}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tx.date} · ${tx.time}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isSent ? '-' : '+'}₹${tx.amount.toStringAsFixed(2)}',
            style: AppTypography.amount(
              size: 16,
              color: isSent ? AppColors.ink : AppColors.mint,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
