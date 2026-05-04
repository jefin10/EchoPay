import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class RequestMoneyPage extends StatefulWidget {
  const RequestMoneyPage({super.key});

  @override
  State<RequestMoneyPage> createState() => _RequestMoneyPageState();
}

class _RequestMoneyPageState extends State<RequestMoneyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _receivedRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');
      if (phoneNumber == null) {
        setState(() {
          _error = 'Phone number not found';
          _isLoading = false;
        });
        return;
      }
      final url = Uri.parse('$GET_REQUESTS_URL?phoneNumber=$phoneNumber');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sentRequests =
              List<Map<String, dynamic>>.from(data['sentRequests'] ?? []);
          _receivedRequests =
              List<Map<String, dynamic>>.from(data['receivedRequests'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load requests';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRequestStatus(int requestId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');
      final url = Uri.parse(UPDATE_REQUEST_URL);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestId': requestId,
          'status': status,
          'phoneNumber': phoneNumber,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully')),
        );
        _loadRequests();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to update request')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showRequestDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestMoneyDialog(onRequestSent: _loadRequests),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 20),
            _tabs(),
            const SizedBox(height: 12),
            Expanded(child: _content()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestDialog,
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.pop,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'New request',
          style: TextStyle(fontWeight: FontWeight.w700),
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
          Text('requests', style: AppTypography.heading(size: 22)),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _tabButton('Received', 0),
            _tabButton('Sent', 1),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2.5),
      );
    }
    if (_error != null) {
      return _emptyState(Icons.error_outline_rounded, _error!);
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _receivedList(),
        _sentList(),
      ],
    );
  }

  Widget _receivedList() {
    if (_receivedRequests.isEmpty) {
      return _emptyState(
          Icons.inbox_outlined, 'No requests received yet.');
    }
    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _receivedRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _receivedCard(_receivedRequests[i]),
      ),
    );
  }

  Widget _sentList() {
    if (_sentRequests.isEmpty) {
      return _emptyState(
          Icons.send_outlined, "You haven't sent any requests.");
    }
    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _sentRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _sentCard(_sentRequests[i]),
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
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
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receivedCard(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final amount = double.tryParse(request['amount'].toString()) ?? 0.0;
    final name =
        request['requester__user__upiName'] as String? ?? 'Unknown';
    final phone =
        request['requester__user__phoneNumber'] as String? ?? '';
    final message = request['message'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(request['created_at'].toString()) ?? DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _personRow(name, phone, status),
          const SizedBox(height: 14),
          _amountRow('Amount requested', amount, createdAt),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"$message"',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateRequestStatus(request['id'], 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coral,
                      side: BorderSide(
                          color: AppColors.coral.withOpacity(0.4),
                          width: 1.5),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _updateRequestStatus(request['id'], 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Pay'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sentCard(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final amount = double.tryParse(request['amount'].toString()) ?? 0.0;
    final name =
        request['requestee__user__upiName'] as String? ?? 'Unknown';
    final phone =
        request['requestee__user__phoneNumber'] as String? ?? '';
    final message = request['message'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(request['created_at'].toString()) ?? DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _personRow(name, phone, status),
          const SizedBox(height: 14),
          _amountRow('You requested', amount, createdAt),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"$message"',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    _updateRequestStatus(request['id'], 'cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: BorderSide(
                      color: AppColors.coral.withOpacity(0.4), width: 1.5),
                ),
                child: const Text('Cancel request'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _personRow(String name, String phone, String status) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
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
                name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                phone,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _statusChip(status),
      ],
    );
  }

  Widget _amountRow(String label, double amount, DateTime date) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.eyebrow(size: 10)),
                const SizedBox(height: 4),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: AppTypography.amount(size: 22),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(date),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.warning;
        break;
      case 'approved':
        color = AppColors.mint;
        break;
      case 'rejected':
      case 'cancelled':
        color = AppColors.coral;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class RequestMoneyDialog extends StatefulWidget {
  final VoidCallback onRequestSent;
  const RequestMoneyDialog({super.key, required this.onRequestSent});

  @override
  State<RequestMoneyDialog> createState() => _RequestMoneyDialogState();
}

class _RequestMoneyDialogState extends State<RequestMoneyDialog> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendRequest() async {
    if (_phoneController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final requesterPhone = prefs.getString('phoneNumber');
      final url = Uri.parse(CREATE_REQUEST_URL);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requesterPhone': requesterPhone,
          'requesteePhone': _phoneController.text.trim(),
          'amount': amount,
          'message': _messageController.text.trim(),
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onRequestSent();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Money request sent')),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to send request')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('new request', style: AppTypography.eyebrow()),
              const SizedBox(height: 6),
              Text(
                'Ask anyone\nto pay you.',
                style: AppTypography.heading(size: 28, weight: FontWeight.w800)
                    .copyWith(height: 1.05),
              ),
              const SizedBox(height: 24),
              _label('Phone number'),
              const SizedBox(height: 8),
              _input(_phoneController, 'Recipient\'s number',
                  TextInputType.phone),
              const SizedBox(height: 16),
              _label('Amount'),
              const SizedBox(height: 8),
              _input(_amountController, '0', TextInputType.number,
                  prefix: '₹ '),
              const SizedBox(height: 16),
              _label('Note (optional)'),
              const SizedBox(height: 8),
              _input(_messageController, 'Add a note', TextInputType.text,
                  maxLines: 2),
              const SizedBox(height: 26),
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
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send request'),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _input(
    TextEditingController controller,
    String hint,
    TextInputType keyboardType, {
    String? prefix,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixText: prefix,
          prefixStyle: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
