import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../voiceToText/voiceToText.dart';
import '../payToContacts/payToContacts.dart';
import '../payToPhoneNumber/payToPhonenumber.dart';
import '../payToUpiId/payToUpiId.dart';
import 'qr_scanner_page.dart';
import 'history_page.dart';
import 'balance_page.dart';
import 'request_money_page.dart';
import 'my_qr_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = '';
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _loadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadRecentTransactions();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? prefs.getString('upiName');
    if (name != null && name.isNotEmpty) {
      setState(() => _userName = name);
      return;
    }
    // Fallback: fetch from profile API
    final phone = prefs.getString('phoneNumber');
    if (phone == null) return;
    try {
      final res =
          await http.get(Uri.parse('$GET_PROFILE_URL?phoneNumber=$phone'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fetchedName = data['upiName'] as String?;
        if (fetchedName != null && mounted) {
          setState(() => _userName = fetchedName);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRecentTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    if (phone == null) {
      setState(() => _loadingTransactions = false);
      return;
    }
    try {
      final res = await http.post(
        Uri.parse(GET_TRANSACTIONS_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phone}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final txData = data['transactions'] as Map<String, dynamic>?;
        if (txData != null) {
          final sent = (txData['sent'] as List? ?? []).map((t) => {
                'type': 'sent',
                'name': t['receiver__user__upiName'] ?? 'Unknown',
                'amount': t['amount']?.toString() ?? '0',
                'timestamp': t['timestamp']?.toString() ?? '',
                'status': t['status'] ?? 'completed',
              });
          final received = (txData['received'] as List? ?? []).map((t) => {
                'type': 'received',
                'name': t['sender__user__upiName'] ?? 'Unknown',
                'amount': t['amount']?.toString() ?? '0',
                'timestamp': t['timestamp']?.toString() ?? '',
                'status': t['status'] ?? 'completed',
              });
          final all = [...sent, ...received];
          all.sort((a, b) =>
              (b['timestamp'] as String).compareTo(a['timestamp'] as String));
          if (mounted) {
            setState(() => _recentTransactions = all.take(3).toList());
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingTransactions = false);
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
              _buildTopRow(),
              const SizedBox(height: 22),
              _buildWalletCard(),
              const SizedBox(height: 28),
              _buildSectionLabel('quick pay'),
              const SizedBox(height: 14),
              _buildQuickActions(),
              const SizedBox(height: 28),
              _buildVoiceBanner(),
              const SizedBox(height: 28),
              _buildSectionLabel('move money'),
              const SizedBox(height: 14),
              _buildTransferGrid(),
              const SizedBox(height: 28),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.pop,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'hey there',
                style: AppTypography.eyebrow(
                    color: AppColors.textSecondary, size: 10),
              ),
              const SizedBox(height: 2),
              Text(
                _userName.isEmpty ? 'Welcome' : _userName,
                style: AppTypography.heading(size: 18),
              ),
            ],
          ),
        ),
        _buildIconButton(
          Icons.qr_code_scanner_rounded,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerPage()),
          ),
        ),
        const SizedBox(width: 10),
        _buildIconButton(Icons.notifications_none_rounded, () {}),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.ink, size: 20),
      ),
    );
  }

  Widget _buildWalletCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BalancePage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'wallet balance',
                  style: AppTypography.eyebrow(
                      color: Colors.white.withOpacity(0.6)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.pop,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LIVE',
                    style: AppTypography.eyebrow(
                        color: AppColors.ink, size: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹',
                  style: AppTypography.amount(
                    size: 32,
                    color: Colors.white.withOpacity(0.7),
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to view',
                  style: AppTypography.amount(size: 30, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EchoPay UPI',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const Icon(Icons.arrow_outward_rounded,
                    color: AppColors.pop, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: AppTypography.eyebrow(color: AppColors.textSecondary));
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _quickAction(
          Icons.qr_code_scanner_rounded,
          'Scan',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerPage()),
          ),
        ),
        const SizedBox(width: 12),
        _quickAction(
          Icons.smartphone_rounded,
          'To phone',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PayToPhonenumberPage()),
          ),
        ),
        const SizedBox(width: 12),
        _quickAction(
          Icons.account_balance_wallet_outlined,
          'Balance',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BalancePage()),
          ),
        ),
        const SizedBox(width: 12),
        _quickAction(
          Icons.receipt_long_rounded,
          'History',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryPage()),
          ),
        ),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.ink, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SpeechScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.popSoft,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.pop.withOpacity(0.55), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.mic_rounded,
                  color: AppColors.pop, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('voice pay',
                      style: AppTypography.eyebrow(color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text('Send ₹500 to John',
                      style: AppTypography.heading(size: 17)),
                  const SizedBox(height: 2),
                  Text(
                    'Just say it. We will do the rest.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: AppColors.ink, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _transferCard(
                Icons.contacts_rounded,
                'To contact',
                'Pick from your address book',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PayToContactsPage()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _transferCard(
                Icons.alternate_email_rounded,
                'To UPI ID',
                'Any UPI handle',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PayToUpiIdPage()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _transferCard(
                Icons.call_received_rounded,
                'Request',
                'Ask anyone to pay you',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RequestMoneyPage()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _transferCard(
                Icons.qr_code_2_rounded,
                'My QR',
                'Show & get paid',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyQRPage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _transferCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.ink, size: 20),
            ),
            const SizedBox(height: 14),
            Text(title, style: AppTypography.heading(size: 15)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('recent', style: AppTypography.eyebrow()),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                ),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_loadingTransactions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.ink, strokeWidth: 2),
              ),
            )
          else if (_recentTransactions.isEmpty)
            _emptyTransactions()
          else
            ..._buildTransactionRows(),
        ],
      ),
    );
  }

  Widget _emptyTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 12),
          const Text(
            'No transactions yet',
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Send your first payment to get started.',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionRows() {
    final rows = <Widget>[];
    for (int i = 0; i < _recentTransactions.length; i++) {
      final t = _recentTransactions[i];
      final isSent = t['type'] == 'sent';
      final name = t['name'] as String;
      final amount = double.tryParse(t['amount'] as String) ?? 0;
      final displayAmt =
          '${isSent ? '-' : '+'}₹${amount.toStringAsFixed(2)}';
      if (i > 0) _buildDivider();
      rows.add(_activityRow(
        isSent ? 'Sent' : 'Received',
        isSent ? 'To $name' : 'From $name',
        displayAmt,
        !isSent,
      ));
      if (i < _recentTransactions.length - 1) {
        rows.add(_buildDivider());
      }
    }
    return rows;
  }

  Widget _buildDivider() => Container(height: 1, color: AppColors.divider);

  Widget _activityRow(
      String title, String subtitle, String amount, bool isCredit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.mint : AppColors.ink,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
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
          Text(
            amount,
            style: TextStyle(
              color: isCredit ? AppColors.mint : AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
