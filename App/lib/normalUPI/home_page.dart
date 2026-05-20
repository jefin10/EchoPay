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
import '../widgets/motion.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String _userName = '';
  String _upiId = '';
  double? _balance;
  bool _balanceHidden = false;
  bool _loadingBalance = true;
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _loadingTransactions = true;

  // Lazy late initializer (not assigned in initState) so a hot reload that
  // adds/changes this field can't leave it uninitialized on a live State.
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.enter);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBalance();
    _loadRecentTransactions();
    // Let the first frame settle, then play the entrance once.
    WidgetsBinding.instance.addPostFrameCallback((_) => _entrance.forward());
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadBalance(), _loadRecentTransactions()]);
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? prefs.getString('upiName');
    final upi = prefs.getString('upiId') ?? prefs.getString('upiMail') ?? '';
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        _upiId = upi;
      });
    }
    if (name != null && name.isNotEmpty) return;
    final phone = prefs.getString('phoneNumber');
    if (phone == null) return;
    try {
      final res =
          await http.get(Uri.parse('$GET_PROFILE_URL?phoneNumber=$phone'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _userName = (data['upiName'] as String?) ?? _userName;
            _upiId = (data['upiId'] as String?) ?? _upiId;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    if (phone == null) {
      if (mounted) setState(() => _loadingBalance = false);
      return;
    }
    try {
      final res =
          await http.get(Uri.parse('$GET_BALANCE_URL?phoneNumber=$phone'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final raw = data['balance'] ?? data['amount'];
        final value = double.tryParse(raw.toString());
        if (mounted && value != null) setState(() => _balance = value);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingBalance = false);
  }

  Future<void> _loadRecentTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    if (phone == null) {
      if (mounted) setState(() => _loadingTransactions = false);
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
            setState(() => _recentTransactions = all.take(4).toList());
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingTransactions = false);
  }

  // ── Formatting helpers (small, human details) ───────────────────────────
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Working late';
  }

  /// Indian digit grouping: 12,48,000.00 — a deliberately local touch.
  String _inr(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    var intPart = parts[0];
    final neg = intPart.startsWith('-');
    if (neg) intPart = intPart.substring(1);
    String grouped;
    if (intPart.length <= 3) {
      grouped = intPart;
    } else {
      final last3 = intPart.substring(intPart.length - 3);
      var rest = intPart.substring(0, intPart.length - 3);
      final buf = <String>[];
      while (rest.length > 2) {
        buf.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) buf.insert(0, rest);
      grouped = '${buf.join(',')},$last3';
    }
    return '${neg ? '-' : ''}$grouped.${parts[1]}';
  }

  String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.ink,
        backgroundColor: AppColors.surface,
        displacement: 28,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stagger(
                  controller: _entrance,
                  enabled: !reduceMotion,
                  children: [
                    _buildTopRow(),
                    const SizedBox(height: 22),
                    _buildWalletCard(),
                    const SizedBox(height: 30),
                    _sectionLabel('quick pay'),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildVoiceBanner(),
                    const SizedBox(height: 30),
                    _sectionLabel('move money'),
                    const SizedBox(height: 12),
                    _buildTransferGrid(),
                    const SizedBox(height: 30),
                    _buildRecentActivity(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildTopRow() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(15),
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
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _userName.isEmpty ? 'Welcome back' : _userName,
                style: AppTypography.heading(size: 19),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _iconButton(
          Icons.qr_code_scanner_rounded,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QRScannerPage())),
        ),
        const SizedBox(width: 10),
        _iconButton(Icons.notifications_none_rounded, () {}),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.ink, size: 20),
      ),
    );
  }

  // ── Wallet hero ─────────────────────────────────────────────────────────
  Widget _buildWalletCard() {
    final maskedUpi = _upiId.isNotEmpty
        ? _upiId
        : (_userName.isNotEmpty
            ? '${_userName.toLowerCase().replaceAll(' ', '')}@upi'
            : 'your-id@upi');

    return Pressable(
      scale: 0.985,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BalancePage()),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha:0.22),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Single-tone glow — depth without a rainbow gradient.
              Positioned(
                right: -64,
                top: -64,
                child: Container(
                  width: 188,
                  height: 188,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pop.withValues(alpha:0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'available balance',
                          style: AppTypography.eyebrow(
                              color: Colors.white.withValues(alpha:0.55)),
                        ),
                        const Spacer(),
                        Pressable(
                          scale: 0.86,
                          onTap: () => setState(
                              () => _balanceHidden = !_balanceHidden),
                          child: Padding(
                            // Invisible padding keeps a comfortable tap
                            // target without a visible chip.
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              _balanceHidden
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildBalanceLine(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            maskedUpi,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.5),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Text(
                              'View statement',
                              style: TextStyle(
                                color: AppColors.pop,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_outward_rounded,
                                color: AppColors.pop, size: 15),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceLine() {
    if (_loadingBalance) {
      return const Shimmer(
        child: SkeletonBar(width: 180, height: 38, dark: true),
      );
    }
    if (_balance == null) {
      return Text(
        'Unavailable',
        style: AppTypography.amount(
            size: 30, color: Colors.white.withValues(alpha:0.7)),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            '₹',
            style: AppTypography.amount(
              size: 24,
              color: Colors.white.withValues(alpha:0.7),
              weight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 5),
        // AnimatedSwitcher so toggling hide/show is a soft crossfade,
        // not an abrupt swap.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: AppMotion.out,
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            _balanceHidden ? '••••••' : _inr(_balance!),
            key: ValueKey(_balanceHidden),
            style: AppTypography.amount(size: 38, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(text,
            style: AppTypography.eyebrow(color: AppColors.textSecondary)),
      );

  // ── Quick actions: one grouped surface, not four lookalike tiles ────────
  Widget _buildQuickActions() {
    final items = [
      (
        Icons.qr_code_scanner_rounded,
        'Scan',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const QRScannerPage())),
      ),
      (
        Icons.smartphone_rounded,
        'To phone',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PayToPhonenumberPage())),
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Balance',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BalancePage())),
      ),
      (
        Icons.receipt_long_rounded,
        'History',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HistoryPage())),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Pressable(
                onTap: items[i].$3,
                child: Column(
                  children: [
                    Icon(items[i].$1, color: AppColors.ink, size: 23),
                    const SizedBox(height: 9),
                    Text(
                      items[i].$2,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1)
              Container(
                width: 1,
                height: 34,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }

  // ── Voice banner ────────────────────────────────────────────────────────
  Widget _buildVoiceBanner() {
    return Pressable(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SpeechScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.popSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.graphic_eq_rounded,
                  color: AppColors.pop, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('voice pay',
                      style: AppTypography.eyebrow(color: AppColors.ink)),
                  const SizedBox(height: 5),
                  Text('“Send ₹500 to John”',
                      style: AppTypography.heading(size: 16)),
                  const SizedBox(height: 2),
                  Text(
                    'Say it once. We handle the rest.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.pop, size: 17),
            ),
          ],
        ),
      ),
    );
  }

  // ── Move money grid ─────────────────────────────────────────────────────
  Widget _buildTransferGrid() {
    final cards = [
      (
        Icons.contacts_rounded,
        'To contact',
        'From your phone',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PayToContactsPage())),
      ),
      (
        Icons.alternate_email_rounded,
        'To UPI ID',
        'Any UPI handle',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PayToUpiIdPage())),
      ),
      (
        Icons.call_received_rounded,
        'Request',
        'Ask anyone to pay you',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RequestMoneyPage())),
      ),
      (
        Icons.qr_code_2_rounded,
        'My QR',
        'Show & get paid',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyQRPage())),
      ),
    ];
    return Column(
      children: [
        for (var r = 0; r < 2; r++) ...[
          if (r != 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _transferCard(cards[r * 2])),
              const SizedBox(width: 12),
              Expanded(child: _transferCard(cards[r * 2 + 1])),
            ],
          ),
        ],
      ],
    );
  }

  Widget _transferCard(
      (IconData, String, String, VoidCallback) c) {
    return Pressable(
      onTap: c.$4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(c.$1, color: AppColors.ink, size: 19),
                ),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded,
                    color: AppColors.textMuted, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(c.$2, style: AppTypography.heading(size: 15)),
            const SizedBox(height: 3),
            Text(
              c.$3,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent activity ─────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
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
              Text('recent activity', style: AppTypography.eyebrow()),
              Pressable(
                scale: 0.94,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoryPage())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_loadingTransactions)
            ...List.generate(3, (i) => _skeletonRow(i == 0))
          else if (_recentTransactions.isEmpty)
            _emptyTransactions()
          else
            for (var i = 0; i < _recentTransactions.length; i++) ...[
              if (i != 0)
                Container(height: 1, color: AppColors.divider),
              _activityRow(_recentTransactions[i]),
            ],
        ],
      ),
    );
  }

  Widget _skeletonRow(bool first) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 14 : 0, bottom: 14),
      child: Shimmer(
        child: Row(
          children: const [
            SkeletonBar(width: 38, height: 38, radius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBar(width: 90, height: 12),
                  SizedBox(height: 7),
                  SkeletonBar(width: 140, height: 10),
                ],
              ),
            ),
            SizedBox(width: 12),
            SkeletonBar(width: 56, height: 14),
          ],
        ),
      ),
    );
  }

  Widget _emptyTransactions() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 26, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nothing here yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your first payment will show up here.',
              textAlign: TextAlign.center,
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

  Widget _activityRow(Map<String, dynamic> t) {
    final isSent = t['type'] == 'sent';
    final name = t['name'] as String;
    final amount = double.tryParse(t['amount'] as String) ?? 0;
    final when = _relativeTime(t['timestamp'] as String);
    return Pressable(
      scale: 0.98,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HistoryPage())),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSent
                    ? AppColors.surfaceDim
                    : AppColors.mint.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSent
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isSent ? AppColors.ink : AppColors.mint,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSent ? 'To $name' : 'From $name',
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    when.isEmpty ? (isSent ? 'Sent' : 'Received') : when,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Text(
              '${isSent ? '-' : '+'}₹${_inr(amount)}',
              style: TextStyle(
                color: isSent ? AppColors.ink : AppColors.mint,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
