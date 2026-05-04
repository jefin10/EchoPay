import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = const ['All', 'Sent', 'Received', 'Failed'];
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');
      if (phoneNumber == null) {
        setState(() {
          _loading = false;
          _error = 'Phone number not found.';
        });
        return;
      }
      final url = Uri.parse(GET_TRANSACTIONS_URL);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> txs = [];
        for (var tx in data['transactions']['sent']) {
          txs.add({
            'type': 'sent',
            'recipient': tx['receiver__user__upiName'],
            'amount': double.tryParse(tx['amount'].toString()) ?? 0.0,
            'date': tx['timestamp']?.split('T')[0] ?? '',
            'time': tx['timestamp']?.split('T').length > 1
                ? tx['timestamp'].split('T')[1].substring(0, 5)
                : '',
            'status': tx['status'] ?? '',
          });
        }
        for (var tx in data['transactions']['received']) {
          txs.add({
            'type': 'received',
            'recipient': tx['sender__user__upiName'],
            'amount': double.tryParse(tx['amount'].toString()) ?? 0.0,
            'date': tx['timestamp']?.split('T')[0] ?? '',
            'time': tx['timestamp']?.split('T').length > 1
                ? tx['timestamp'].split('T')[1].substring(0, 5)
                : '',
            'status': tx['status'] ?? '',
          });
        }
        setState(() {
          _transactions = txs;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to fetch transactions.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error: $e';
      });
    }
  }

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
          return GestureDetector(
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2.5),
      );
    }
    if (_error != null) {
      return _emptyState(Icons.error_outline_rounded, _error!);
    }
    final filtered = _selectedFilter == 'All'
        ? _transactions
        : _transactions.where((tx) {
            if (_selectedFilter == 'Sent') return tx['type'] == 'sent';
            if (_selectedFilter == 'Received') return tx['type'] == 'received';
            if (_selectedFilter == 'Failed') return tx['status'] == 'failed';
            return true;
          }).toList();
    if (filtered.isEmpty) {
      return _emptyState(Icons.receipt_long_outlined,
          'Nothing here yet — your transactions will land here.');
    }
    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: _fetchTransactions,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _txTile(filtered[i]),
      ),
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

  Widget _txTile(Map<String, dynamic> tx) {
    final isSent = tx['type'] == 'sent';
    final isCompleted = tx['status'] == 'completed';
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
                      ? 'To ${tx['recipient']}'
                      : 'From ${tx['recipient']}',
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
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx['status'].toString().toUpperCase(),
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
                      '${tx['date']} · ${tx['time']}',
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
            '${isSent ? '-' : '+'}₹${tx['amount'].toStringAsFixed(2)}',
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
